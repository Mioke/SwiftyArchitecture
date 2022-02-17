//
//  AppContext.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift

public let kAppContextChangedNotification = NSNotification.Name(rawValue: "kAppContextChangedNotification")

public class AppContext: NSObject {
    
    public static let standard = DefaultAppContext()
    public static var current = standard {
        didSet {
            guard oldValue != current else { return }
            NotificationCenter.default.post(name: kAppContextChangedNotification, object: current)
        }
    }

    // MARK: - User
    public internal(set) var user: UserProtocol
    
    public var userId: String {
        return user.userId
    }
    
    public init(user: UserProtocol) {
        self.user = user
        authController = .init(configuration: user.authConfiguration)
        super.init()
        self.dataCenter = DataCenter(appContext: self)
    }
    
    let authController: AuthController
    
    public weak var authDelegate: AuthControllerDelegate? {
        didSet {
            authController.delegate = authDelegate
        }
    }
    
    // MARK: - Data Center
    public var dataCenter: DataCenter!
}

public protocol UserAchivableInfoProtocol: Codable {
    static func decode(_ data: Data) throws -> Self
    func encode() throws -> Data
}

public protocol UserProtocol {
    var userId: String { get set }
    var authState: BehaviorSubject<AuthState> { get set }
    
    var authConfiguration: AuthController.Configuration { get }
    
    var archivableInfoType: UserAchivableInfoProtocol.Type { get }
    var archivableInfo: UserAchivableInfoProtocol { get set }
}

public enum AuthState {
    case unauthenticated
    case authenticated
    case presession
}

final public class DefaultAppContext: AppContext {
    
    convenience init() {
        self.init(user: DefaultUser())
    }
    
    private override init(user: UserProtocol) {
        super.init(user: user)
    }
}

private struct DefaultUser: UserProtocol {
    var authConfiguration: AuthController.Configuration = .init(archiveLocation: .database)
    
    var authState: BehaviorSubject<AuthState> = .init(value: .authenticated)
    var userId: String = "__standard__"
    
    var archivableInfoType: UserAchivableInfoProtocol.Type {
        return type(of: userId)
    }
    var archivableInfo: UserAchivableInfoProtocol {
        get { return userId }
        set { }
    }
}

extension String: UserAchivableInfoProtocol {
    public static func decode(_ data: Data) throws -> String {
        try JSONDecoder().decode(self, from: data)
    }
    
    public func encode() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

// MARK: - Convenience
public func AppContextCurrentDatabase() -> Realm {
    return AppContext.current.dataCenter.db.realm
}

public func AppContextCurrentMemory() -> Realm {
    return AppContext.current.dataCenter.memory.realm
}
