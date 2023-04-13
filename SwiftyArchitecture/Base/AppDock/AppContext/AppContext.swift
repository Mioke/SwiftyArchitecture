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
    
    public static let standard: StandardAppContext = .init()
    public static var current: AppContext = standard {
        didSet {
            guard oldValue != current else { return }
            NotificationCenter.default.post(name: kAppContextChangedNotification, object: current)
        }
    }
    
    public struct Consts {
        /// Only for the `AppContext` created by the startup logic in `StandardAppContext`, modify this property when
        /// your database schema version is changing.
        public static var storeVersions: StoreVersions = .init(cacheVersion: 1, persistanceVersion: 1)
    }

    // MARK: - User
    public internal(set) var user: UserProtocol
    
    /// The state indicate the user session. This property should not be record, so if your user model self is
    /// `Codable`, please remove this from coding keys.
    public var authState: BehaviorSubject<AuthState> = .init(value: .unauthenticated)
    
    public var userId: String {
        return user.id
    }
    
    public init(user: UserProtocol, storeVersions: StoreVersions) {
        self.user = user
        self.storeVersions = storeVersions
        super.init()
    }
    
    public static var authController: AuthController = .init(delegate: nil)
    
    /// Start a new app context.
    /// - Parameter user: the user of this context.
    public static func startAppContext(with user: UserProtocol, storeVersions: StoreVersions) -> Void {
        let appContext = AppContext(user: user, storeVersions: storeVersions)
        appContext.authState.onNext(.authenticated)
        AppContext.current = appContext
        AppContext.standard.archive(appContext: appContext)
            .then(AppContext.standard.createOrUpdateUserMata(with: appContext.user.id))
            .subscribe()
            .disposed(by: AppContext.standard.disposables)
    }
    
    /// Any changes of the user should call this function to update the context.
    /// - Parameter user: The new users.
    /// - Returns: Handling signal.
    @discardableResult
    public func update(user: UserProtocol) -> ObservableSignal {
        guard user.id == self.user.id else {
            fatalError("Update user must use the same user id.")
        }
        KitLogger.info("Updating user of id: \(user.id)")
        self.user = user
        return AppContext.standard.archive(appContext: self)
    }
    
    // MARK: - Data Center
    public lazy var store: Store = try! Store(appContext: self)
    
    weak var storeDelegate: AppContextStoreDelegate?
    
    public struct StoreVersions {
        public let cacheVersion: UInt64
        public let persistanceVersion: UInt64
        
        public init(cacheVersion: UInt64, persistanceVersion: UInt64) {
            self.cacheVersion = cacheVersion
            self.persistanceVersion = persistanceVersion
        }
    }
    
    let storeVersions: StoreVersions
}

public protocol AppContextStoreDelegate: AnyObject {
    func realmDataBasePerform(migration: Migration, oldSchema: UInt64)
}

// MARK: - Convenience
public func AppContextCurrentPersistance() throws -> Realm {
    return try AppContext.current.store.persistance.currentThreadInstance
}

public func AppContextCurrentCache() throws -> Realm {
    return try AppContext.current.store.cache.currentThreadInstance
}

public func AppContextCurrentMemory() throws -> Realm {
    return try AppContext.current.store.memory.currentThreadInstance
}
