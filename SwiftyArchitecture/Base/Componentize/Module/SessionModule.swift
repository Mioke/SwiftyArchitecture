//
//  SessionModule.swift
//  MIOSwiftyArchitecture
//
//  Created by Mioke Klein on 2022/1/8.
//

import Foundation

public protocol SessionModuleProtocol: ModuleProtocol {
    static func sessionDidAuthenticate(with userID: String)
    static func sessionDidDeauthenticate(with userID: String)
}

public struct UserSession {
    public let userID: String
}

public extension ModuleManager {
    func beginUserSession(with userID: String) {
        session = UserSession(userID: userID)
        moduleMap.values
            .compactMap { $0 as? SessionModuleProtocol.Type }
            .forEach { $0.sessionDidAuthenticate(with: userID) }
    }
    
    func endUserSession(with userID: String) {
        session = nil
        moduleMap.values
            .compactMap { $0 as? SessionModuleProtocol.Type }
            .forEach { $0.sessionDidDeauthenticate(with: userID) }
    }
}
