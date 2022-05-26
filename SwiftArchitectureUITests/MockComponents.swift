//
//  MockComponents.swift
//  SwiftArchitectureUITests
//
//  Created by KelanJiang on 2022/5/24.
//  Copyright © 2022 KleinMioke. All rights reserved.
//

import Foundation
@testable import MIOSwiftyArchitecture
import AuthProtocol
import Auth
import ApplicationProtocol
import Application


class MockAuth: ModuleProtocol {
    
    func moduleDidLoad(with manager: ModuleManager) {
        // mocked module will never running this method.
    }
    
    static var moduleIdentifier: ModuleIdentifier {
        return .auth
    }
    
    required init() {
        
    }
}

extension MockAuth: AuthServiceProtocol {
    
    func authenticate(completion: @escaping (User) -> ()) throws {
        let user = User(id: "15780")
        ModuleManager.default.beginUserSession(with: user.id)
        self.markAsReleasing()
    }
    
    func refreshAuthenticationIfNeeded(completion: @escaping (User) -> ()) {
        if let previousUID = AppContext.standard.previousLaunchedUserId {
            let previousUser = User(id: previousUID)
            let previousContext = AppContext(user: previousUser)
            // get token from previous context data center, like:
            // let credential = previousContext.dataCenter.object(with: previousUID, type: Credential.Type)
            print(previousContext)
            // and then do some refresh token logic here.
        }
    }
    
    func deauthenticate(completion: @escaping (Error?) -> Void) {
        
    }
}
