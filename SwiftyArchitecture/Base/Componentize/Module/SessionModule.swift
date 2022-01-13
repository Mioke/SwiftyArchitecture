//
//  SessionModule.swift
//  MIOSwiftyArchitecture
//
//  Created by Mioke Klein on 2022/1/8.
//

import Foundation

public protocol SessionModuleProtocol: ModuleProtocol {
    func sessionDidAuthenticate(with userID: String)
    func sessionDidDeauthenticate(with userID: String)
}

public struct UserSession {
    public let userID: String
}

public extension ModuleManager {
    func beginUserSession(with userID: String) {
        session = UserSession(userID: userID)
        moduleCache.values
            .compactMap { $0 as? SessionModuleProtocol }
            .forEach { $0.sessionDidAuthenticate(with: userID) }
    }
    
    func endUserSession(with userID: String) {
        session = nil
        moduleCache.values
            .compactMap { $0 as? SessionModuleProtocol }
            .forEach { $0.sessionDidDeauthenticate(with: userID) }
    }
}
