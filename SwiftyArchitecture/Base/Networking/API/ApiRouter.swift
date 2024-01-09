//
//  APIRouter.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/5/27.
//

import Foundation

protocol ApiRouter: AnyObject {
    func route<T: ApiInfoProtocol>(api: API<T>) throws -> Void
}

protocol APIRouterMokerDataSource: AnyObject {
    func construct<T>(type: T.Type) -> ((T.RequestParam?) -> T.ResultType)? where T : ApiInfoProtocol
}

class ApiRouterContainer {
    
    static let shared: ApiRouterContainer = .init()
    
    private let builtinRouter = BuiltinApiRouter()
    private lazy var routerMocker = { () -> ApiRouterMocker in
        let mocker = ApiRouterMocker()
        mocker.datasource = self
        return mocker
    }()
    
    private var injectedTypesMap: [String: Any] = [:]
    
    func router<T>(withType type: T.Type) -> ApiRouter {
        let name = String(reflecting: type)
        return injectedTypesMap[name] != nil ? routerMocker : builtinRouter
    }
    
    func injectAPI<T>(with type: T.Type,
                      customize: @escaping (_ param: T.RequestParam?) -> T.ResultType)
    -> Void where T: ApiInfoProtocol {
        injectedTypesMap[String(reflecting: type)] = customize
    }
    
    func remove<T>(type: T.Type) {
        injectedTypesMap[String(reflecting: type)] = nil
    }
    
    func reset() {
        injectedTypesMap = [:]
    }
}

extension ApiRouterContainer: APIRouterMokerDataSource {
    
    func construct<T>(type: T.Type) -> ((T.RequestParam?) -> T.ResultType)? where T : ApiInfoProtocol {
        let name = String(reflecting: type)
        return injectedTypesMap[name] as? (T.RequestParam?) -> T.ResultType
    }
}
