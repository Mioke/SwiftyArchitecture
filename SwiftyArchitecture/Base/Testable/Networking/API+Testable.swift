//
//  ModuleManager+Testable.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/5/23.
//

import Foundation

public class APIMocker {
    
    public static func mock<T: ApiInfoProtocol>(type: T.Type, customize: @escaping (T.RequestParam?) -> T.ResultType) -> Void {
        ApiRouterContainer.shared.injectAPI(with: T.self, customize: customize)
    }
    
    public static func recover<T: ApiInfoProtocol>(type: T.Type) -> Void {
        ApiRouterContainer.shared.remove(type: T.self)
    }
    
    public static func reset() {
        ApiRouterContainer.shared.reset()
    }
}
