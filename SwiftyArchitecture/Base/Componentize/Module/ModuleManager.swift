//
//  ModuleManager.swift
//  Pods
//
//  Created by Mioke Klein on 2022/1/8.
//

import UIKit
import ObjectiveC

public typealias ModuleIdentifier = String

/// The entrance of a module, the module manager will find this entrance by the module identifier
/// provided from a requester.
public protocol ModuleProtocol: AnyObject {
    static var moduleIdentifier: ModuleIdentifier { get }
    
    init()
    func moduleDidLoad(with manager: ModuleManager)
}

// Convenience for modules to get their manager.
private var moduleManagerKey: UInt8 = 0
public extension ModuleProtocol {
    var moduleManager: ModuleManager? {
        set {
            objc_setAssociatedObject(self, &moduleManagerKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &moduleManagerKey) as? ModuleManager
        }
    }
    
    init(with manager: ModuleManager) {
        self.init()
        moduleManager = manager
    }
}

/// The modules' manager, register modules from a property list. Provided a `default` singleton, but
/// you still can create any new manager for your own.
public final class ModuleManager: NSObject {
    
    public static let `default` = ModuleManager()
    
    public lazy var bridge = ModuleBridge(with: self)
    
    public var session: UserSession? = nil
    
    internal var moduleList: ModuleList? {
        didSet {
            guard let moduleList = moduleList else {
                moduleMap = [:]
                return
            }
            moduleMap = moduleList.internalModules
                .reduce([ModuleIdentifier: ModuleProtocol.Type](), { partialResult, module in
                    guard let clazz = module.bridgingClass else { return partialResult }
                    return partialResult + [clazz.moduleIdentifier: clazz]
            })
        }
    }
    
    var moduleMap: [ModuleIdentifier: ModuleProtocol.Type] = [:]
    var moduleCache: [ModuleIdentifier: ModuleProtocol] = [:]
    
    public
    func registerModules(withConfigFilePath path: URL) throws -> Void {
        let content = try Data(contentsOf: path)
        let decoder = PropertyListDecoder()
        moduleList = try decoder.decode(ModuleList.self, from: content)
    }
    
    // MARK: - Initiator
    public lazy var initiator: Initiator = .init(moduleManager: self)
}

public enum ModuleError: Error {
    case noRegister
}

// MARK: - Internal - Registery
struct ModuleList: Codable {
    let modules: [String]
    
    enum CodingKeys: String, CodingKey {
        case modules = "modules"
    }
}

extension ModuleList {
    var internalModules: [Module] {
        return modules.map { Module(className: $0) }
    }
}

struct Module {
    let className: String
    
    var bridgingClass: ModuleProtocol.Type? {
        if let clazz = Bundle.main.classNamed(className) as? ModuleProtocol.Type {
            return clazz
        }
        if let clazz = NSClassFromString(className) as? ModuleProtocol.Type {
            return clazz
        }
        return nil
    }
}

// MARK: - Method bridging

public class ModuleBridge: NSObject {
    private unowned let manager: ModuleManager
    
    init(with manager: ModuleManager) {
        self.manager = manager
    }
    
    public
    func resolve(_ moduleIdentifier: ModuleIdentifier) throws -> ModuleProtocol? {
        if let cached = manager.moduleCache[moduleIdentifier] {
            return cached
        }
        guard let type = manager.moduleMap[moduleIdentifier] else {
            throw ModuleError.noRegister
        }
        return createModule(with: type)
    }
    
    private func createModule(with type: ModuleProtocol.Type) -> ModuleProtocol {
        let module = type.init(with: manager)
        manager.moduleCache[type.moduleIdentifier] = module
        module.moduleDidLoad(with: manager)
        return module
    }
}

// MARK: - Deallocating

extension ModuleProtocol {
    public
    func markAsReleasing() {
        moduleManager?.moduleCache[Self.moduleIdentifier] = nil
    }
}
