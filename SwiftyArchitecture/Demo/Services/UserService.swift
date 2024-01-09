//
//  UserService.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/24.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import MIOSwiftyArchitecture
import RxSwift
import AuthProtocol

class UserService: NSObject {
    
    static let shared: UserService = .init()
    
    @discardableResult
    func login() -> ObservableSignal {
        return .create { observer in
            do {
                if let authModule = try ModuleManager.default.bridge.resolve(.auth) as? AuthServiceProtocol {
                    try authModule.authenticate { user in
                        AppContext.startAppContext(with: user, storeVersions: AppContext.Consts.storeVersions)
                        observer.signal()
                        observer.onCompleted()
                    }
                }
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func genRandomToken() -> String {
        let len = 12
        let codec = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-="
        
        return (0..<len).map { _ in
            String(codec.randomElement()!)
        }
        .joined()
    }
}

extension UserService: AuthControllerDelegate {
    func shouldRefreshAuthentication(with user: UserProtocol, isStartup: Bool) -> Bool {
        // we can refresh authentication everytime when app startup.
        if isStartup {
            return true
        }
        // or we can trust the `expiration` of the user we stored.
        guard let user = user as? TestUser else {
            assert(false, "This application should use `TestUser` as the UserProtocol.")
            return true
        }
        guard let expiration = user.expiration else { return true }
        return expiration < Date()
    }
    
    func refreshAuthentication(with user: UserProtocol) -> Observable<UserProtocol> {
        guard let user = user as? TestUser else { return .error(KitErrors.unknown) }
        
        return .just(TestUser(id: user.id, age: user.age + 1, token: UserService.shared.genRandomToken()))
            .delay(.seconds(3), scheduler: SerialDispatchQueueScheduler.init(qos: .default))
    }
    
    func deauthenticate() -> ObservableSignal {
        return .signal
    }
}

enum UserServiceError: Error {
    case unknown
}
