//
//  Navigation+Private.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2023/4/4.
//

import Foundation

struct RegisteryFile: Codable {
    
    let modules: [Module]
    var indexedModules: [String: Module]?
    
    enum CodingKeys: String, CodingKey {
        case modules = "Modules"
    }
    
    mutating func index() {
        indexedModules = modules.reduce([String: Module]()) { partialResult, module in
            return partialResult + [module.id: module]
        }
    }
    
    struct Module: Codable {
        typealias PathName = String
        
        let id: String
        let handler: String?
        let paths: [PathName: Target]
    }
    
    struct Target: Codable {
        let target: String
        let isAccessibleExternally: Bool?
    }
}

class RegisteryFileCache {
    /// Singleton of `RegisteryFileCache`
    static let shared: RegisteryFileCache = .init()
    
    @ThreadSafe
    var file: RegisteryFile? = nil
}

extension Navigation {
    
    func loadCache() throws -> RegisteryFile {
        if let file = RegisteryFileCache.shared.file {
            return file
        }
        guard let registeryURL = self.registeryFileURL else {
            throw NavigationError.registeryFileNotSetYet
        }
        guard let content = FileManager.default.contents(atPath: registeryURL.path),
              var file = try? PropertyListDecoder().decode(RegisteryFile.self, from: content)
        else {
            throw NavigationError.registeryFileContentInvalid
        }
        file.index()
        RegisteryFileCache.shared.file = file
        return file
    }
    
    func findModule(with name: String) throws -> RegisteryFile.Module {
        let file = try loadCache()
        guard let modules = file.indexedModules else {
            throw NavigationError.moduleIndexFailed
        }
        guard let module = modules[name] else {
            throw NavigationError.moduleNotExists
        }
        return module
    }
    
    func handler(of module: RegisteryFile.Module) throws -> (any NavigationModuleHandlerProtocol.Type)? {
        guard let className = module.handler else { return nil }
        guard let clazz = NSClassFromString(className) as? any NavigationModuleHandlerProtocol.Type else {
            throw NavigationError.moduleHandlerClassNotExists
        }
        return clazz
    }
    
    func validateNavigation(with url: NavigationURL, in module: RegisteryFile.Module) throws {
        if isExternal(with: url) {
            guard let path = url.paths.first,
                  let target = module.paths[path] else {
                return
            }
            guard let isAccessibleExternally = target.isAccessibleExternally, isAccessibleExternally else {
                throw NavigationError.externalLinkNotRegistered
            }
        }
    }
    
    func navigate(with handler: any NavigationModuleHandlerProtocol.Type,
                  `in` module: RegisteryFile.Module,
                  navigationURL: NavigationURL,
                  configuration: Navigation.Configuration,
                  completion: @escaping (Error?) -> Void) {
        processQueue.async { [weak self] in
            // 2. should navigate -> bool
            handler.shouldNavigate(to: navigationURL) { [weak self] result in
                guard let self else { return }
                switch result {
                case .pass:
                    // 3. will navigate
                    handler.willNavigate(to: navigationURL)
                    let error = navigate(to: navigationURL, in: module, configuration: configuration)
                    // 6. did navigate
                    if error == nil { handler.didNavigate(to: navigationURL) }
                    completion(error)
                case .reject(reason: let reason):
                    KitLogger.info("URL: \(navigationURL) rejected because of reason: \(reason).")
                    completion(reason)
                case .redirect(url: let url):
                    DispatchQueue.main.async {
                        do {
                            try self.navigate(to: url, configuration: configuration)
                            completion(nil)
                        } catch {
                            KitLogger.info("Redirect to url: \(url) failed with error: \(error)")
                            completion(NavigationError.redirectFailed(underlying: error))
                        }
                    }
                }
            }
        }
    }
    
    func navigate(to url: NavigationURL,
                  `in` module: RegisteryFile.Module,
                  configuration: Navigation.Configuration)
    -> Error? {
        // 4. find handler -> vc
        guard let path = url.paths.first,
              let target = module.paths[path],
              let clazz = NSClassFromString(target.target) as? NavigationTargetProtocol.Type
        else {
            return NavigationError.targetClassNotExists
        }

        // 5. push or present it
        let work: () -> Error? = {
            let subpaths: [String] = .init(url.paths[1...])
            var vcs = clazz.createTarget(subPaths: subpaths, queries: url.queries, configuration: configuration)
            
            guard vcs.count > 0 else {
                return NavigationError.generateEmptyViewControllers
            }
            guard let frontmostController = NavigationUtils.frontmostViewController() else {
                return NavigationError.cantFindFrontmostViewController
            }
            
            if case .present(style: let style) = configuration.presentationMode {
                vcs.enumerated().forEach { index, element in
                    element.modalPresentationStyle = style
                    frontmostController.present(element, animated: index == vcs.count - 1 ? configuration.animated : false)
                }
            } else {
                guard let navi = frontmostController.navigationController else {
                    return NavigationError.noNavigationController
                }
                navi.pushViewController(vcs.removeLast(), animated: configuration.animated)
                if vcs.count > 0 {
                    DispatchQueue.main.async {
                        var vcStack = navi.viewControllers
                        vcStack.insert(contentsOf: vcs, at: vcStack.count - 2)
                        navi.viewControllers = vcStack
                    }
                }
            }
            return nil
        }
        // guard the work process running on main queue
        return syncMainQueue(execute: work)
    }
    
    func syncMainQueue<T>(execute work: () throws -> T) rethrows -> T {
        if Thread.current.isMainThread {
            return try work()
        } else {
            return try DispatchQueue.main.sync(execute: work)
        }
    }
}
