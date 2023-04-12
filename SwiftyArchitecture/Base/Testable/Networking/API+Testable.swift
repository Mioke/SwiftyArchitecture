//
//  ModuleManager+Testable.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/5/23.
//

import Foundation

public class APIMocker {
    
    public static func mock<T: ApiInfoProtocol>(type: T.Type, customize: @escaping (T.RequestParam?) -> T.ResultType) -> Void {
        APIRouterContainer.shared.injectAPI(with: T.self, customize: customize)
    }
    
    public static func recover<T: ApiInfoProtocol>(type: T.Type) -> Void {
        APIRouterContainer.shared.remove(type: T.self)
    }
    
    public static func reset() {
        APIRouterContainer.shared.reset()
    }
}
