//
//  ModuleManager+Testable.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/5/23.
//

import Foundation

public class APIMocker {
    
    static func mock<T: ApiInfoProtocol>(type: T.Type, customize: @escaping ([String: Any]?) -> T.ResultType) -> Void {
        APIRouterContainer.shared.injectAPI(with: T.self, customize: customize)
    }
    
    static func recover<T: ApiInfoProtocol>(type: T.Type) -> Void {
        APIRouterContainer.shared.remove(type: T.self)
    }
    
    static func reset() {
        APIRouterContainer.shared.reset()
    }
}
