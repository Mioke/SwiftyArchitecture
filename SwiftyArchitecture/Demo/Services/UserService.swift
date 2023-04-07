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

class UserService: NSObject {
    
    static let shared: UserService = .init()
    
    // Singleton model
    static let currentUser = UserModel(name: "defaultUser", uid: 0)
    
    var user: UserModel {
        get { return UserService.currentUser }
    }
    
    @discardableResult
    func login() -> Bool {
        let user = TestUser(id: "test_user",
                            age: 11,
                            token: self.genRandomToken())
        AppContext.startAppContext(with: user)
        return true
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

class TestUser: UserProtocol, Codable {
    var id: String
    var age: Int
    var token: String
    var expiration: Date?
    var authState: BehaviorSubject<AuthState> = .init(value: .unauthenticated)
    var contextConfiguration: StandardAppContext.Configuration = .init(archiveLocation: .database)
    
    enum CodingKeys: CodingKey {
        case id
        case age
        case token
        case expiration
    }
    
    init(id: String, age: Int, token: String) {
        self.id = id
        self.age = age
        self.token = token
        self.expiration = Date().offsetWeek(1)
    }
}

extension TestUser {
    var customDebugDescription: String {
        return "id - \(id), age - \(age)\ntoken: \(token)"
    }
}

extension UserService: AuthControllerDelegate {
    func shouldRefreshAuthentication(with user: UserProtocol) -> Bool {
        guard let user = user as? TestUser else {
            assert(false, "This application should use `TestUser` as the UserProtocol.")
            return true
        }
        guard let expiration = user.expiration else { return true }
        return expiration < Date()
    }
    
    func refreshAuthentication(with user: UserProtocol) -> Observable<UserProtocol> {
        return .just(TestUser(id: "test_user", age: 12, token: UserService.shared.genRandomToken()))
            .delay(.seconds(3), scheduler: SerialDispatchQueueScheduler.init(qos: .default))
    }
    
    func deauthenticate() -> ObservableSignal {
        return .signal
    }
}

enum UserServiceError: Error {
    case unknown
}
