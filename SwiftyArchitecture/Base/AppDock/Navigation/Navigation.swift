//
//  Navigation.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2021/11/30.
//

import UIKit

public protocol NavigationModuleHandlerProtocol: AnyObject {
    static func shouldNavigate(to url: NavigationURL, decisionHandler: @escaping (Navigation.Decision) -> Void) -> Void
    static func willNavigate(to url: NavigationURL) -> Void
    static func didNavigate(to url: NavigationURL) -> Void
}

public protocol NavigationTargetProtocol: AnyObject {
    static func createTarget(
        subPaths: [String],
        queries: [NavigationURL.QueryItem],
        configuration: Navigation.Configuration) -> [UIViewController]
}

/**
 The navigatoin center for an application, can translate URL string and navigate to the designated page.
 
 Design of navigation: we want to support the in-app navigation and external link that comes from other apps.
 Basically we'd like to design the url like:
 ```
 <scheme>://<host>/<module>/<path>/<sub_path1>?var1=value1&var2=value2
 
 for example: sa://com.mioke.swifty-architecture/home/setting?edit=1
 ```
 just similar to the design of the http url.
 
 And sometimes we want to seperate the internal link and external link for the safety purpose, so we design the
 external link can be translate to an internal link. The only difference between internal link and external link is
 the scheme of them, like we can set the external link scheme as `google://` and internal link as `google-internal://`.
 
 For the universal link(which link to your website), like `https://www.google.com/module/path` will automatically
 jump to your application and translate to an internal link(aka. in-app navigation url) and then open it if possible.
 For more information about universal link and associate domain, please see [universal link documents](https://developer.apple.com/ios/universal-links/)
 and [associate domain documents](https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content)
 
*/

public class Navigation {
    
    let parser: LinkParser
    public let enablePageGroup: Bool
    var registeryFileURL: URL? = nil {
        didSet { RegisteryFileCache.shared.file = nil }
    }
    let processQueue: DispatchQueue = .init(label: Consts.domainPrefix + "-navigation")
    
    public init(inAppLinkScheme: String, universalLinkScheme: String, host: String, enablePageGroup: Bool = true) {
        parser = LinkParser(universalLinkScheme: universalLinkScheme, inAppLinkScheme: inAppLinkScheme, host: host)
        self.enablePageGroup = enablePageGroup
    }
    
    public func setRegisteryFile(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NavigationError.fileNotExists
        }
        registeryFileURL = url
    }
    
    public func navigate(to urlString: String,
                         configuration: Navigation.Configuration = .default,
                         completion: ((Swift.Result<Void, Error>) -> Void)? = nil) throws {
        try navigate(to: parser.parse(urlString: urlString), configuration: configuration, completion: completion)
    }
    
    public func navigate(
        to navigationURL: NavigationURL,
        configuration: Navigation.Configuration = .default,
        completion: ((Swift.Result<Void, Error>) -> Void)? = nil)
    throws -> Void {
        // 1. find module
        let module = try findModule(with: navigationURL.module)
        let handler = try handler(of: module)
        
        try validateNavigation(with: navigationURL, in: module)
        
        func complete(with error: Error?) {
            let result: Swift.Result<Void, Error> = error == nil ? .success(()) : .failure(error!)
            completion?(result)
        }
    
        if let handler = handler {
            navigate(with: handler, in: module, navigationURL: navigationURL, configuration: configuration) { error in
                complete(with: error)
            }
        } else {
            let maybeError = navigate(to: navigationURL, in: module, configuration: configuration)
            complete(with: maybeError)
        }
    }
    
    public func handle(open contexts: Set<UIOpenURLContext>) -> Bool {
        let valids = contexts.compactMap { context in
            if let url = NavigationURL(from: context.url), isExternal(with: url), context.options.openInPlace == false {
                return (url, context)
            }
            return nil
        }
        guard valids.count > 0 else { return false }
        do {
            try valids.forEach { (url, context) in
                try navigate(to: url)
            }
        } catch {
            KitLogger.info("Handle open URL failed with error: \(error)")
        }
        return true
    }
    
    public enum Decision {
        case pass
        case reject(reason: Error)
        case redirect(url: NavigationURL)
    }
    
    public enum NavigationError: Error {
        case fileNotExists
        case registeryFileNotSetYet
        case registeryFileContentInvalid
        case moduleIndexFailed
        case moduleNotExists
        case moduleHandlerClassNotExists
        
        case externalLinkNotRegistered
        
        case targetClassNotExists
        case generateEmptyViewControllers
        case cantFindFrontmostViewController
        case noNavigationController
        
        case urlRejected
        case redirectFailed(underlying: Error)
        
        case pageGroupDisabled
    }
    
    var pageGroupStack: Stack<PageGroup> = .init([])
}

extension Navigation {
    
    public struct Configuration {
        
        public enum PresentationModel {
            case push
            case present(style: UIModalPresentationStyle)
        }
        
        public var presentationMode: PresentationModel
        public var animated: Bool
        
        public static let `default`: Configuration = Configuration(presentationMode: .push, animated: true)
    }
    
    public struct PageGroup {
        weak var beginIndex: UIViewController?
        let indexType: BeginIndexType
        let presentationMode: Navigation.Configuration.PresentationModel
        
        enum BeginIndexType {
            case navigationController
            case viewController
            case tabBarController
        }
    }
    
}

// Utils
extension Navigation {
    public func createNavigationURL(
        withModule module: String,
        paths: [String],
        queries: [NavigationURL.QueryItem] = []
    ) -> NavigationURL {
        return NavigationURL(
            scheme: parser.inAppLinkScheme,
            host: parser.host,
            module: module,
            paths: paths,
            queries: queries)
    }
    
    public func isExternal(with url: NavigationURL) -> Bool {
        return parser.isExternalLink(url: url)
    }
}

public struct NavigationURL {
    public let scheme: String
    public let host: String
    public let module: String
    public let paths: [String]
    public var queries: [QueryItem] = []
    
    public var absoluteString: String {
        if let innerURL = innerURL {
            return innerURL.absoluteString
        } else {
            var string = "\(scheme)://\(host)/\(module)/\(paths.joined(separator: "/"))"
            if queries.count > 0 {
                string += "?\(queries.compactMap { $0.absoluteString }.joined(separator: "&"))"
            }
            return string
        }
    }
    
    public mutating func append(queryItem: QueryItem) {
        queries.append(queryItem)
    }
    
    private var innerURL: URL?
    
    public init?(from url: URL) {
        guard let scheme = url.scheme, let host = url.getHost else {
            return nil
        }
        innerURL = url
        
        self.scheme = scheme
        self.host = host
        if let queryString = url.query {
            self.queries = queryString.components(separatedBy: "&").compactMap { string in
                let items = string.components(separatedBy: "=")
                guard items.count == 2,
                      let decodedKey = items[0].removingPercentEncoding,
                      let decodedValue = items[1].removingPercentEncoding
                else { return nil }
                return QueryItem(key: decodedKey, value: decodedValue)
            }
        }
        
        let path = url.getPath
        var components = path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).components(separatedBy: "/")
        guard components.count > 0 else { return nil }
        self.module = components.removeFirst()
        self.paths = components
    }
    
    public init?(from urlString: String) {
        guard let url = URL(string: urlString) else { return nil }
        self.init(from: url)
    }
    
    public init(scheme: String,
                host: String,
                module: String,
                paths: [String],
                queries: [QueryItem]) {
        self.scheme = scheme
        self.module = module
        self.host = host
        self.paths = paths
        self.queries = queries
    }
    
    public struct QueryItem {
        public let key: String
        public var value: String
        
        var absoluteString: String? {
            return escape(key) + "=" + escape(value)
        }
    }
}
