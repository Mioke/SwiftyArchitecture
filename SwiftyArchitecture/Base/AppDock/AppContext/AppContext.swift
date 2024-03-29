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
    
    /// The current application context, default is the `StandardAppContext`.
    public internal(set) static var current: AppContext = standard {
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
    
    /// Start a new app context, and auth context is `authenticated`.
    /// - Important: Normally you shouldn't use this function directly, please use `StandardAppContext.triggerLoggin`.
    /// But if your application don't need to do complicated authentication with server, you can just call this function
    /// to create a locally user context.
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
            assertionFailure("Update user must use the same user id.")
            return .error(todo_error())
        }
        KitLogger.info("Updating user of id: \(user.id)")
        return AppContext.standard.archive(appContext: self).do { _ in self.user = user }
    }
    
    public func refreshAuthentication() -> ObservableSignal {
        return AppContext.standard.refreshAuthentication(isStartup: false)
    }
    
    public func logout() -> ObservableSignal {
        guard let delegate = AppContext.authController.delegate else { return .error(KitErrors.noDelegateError) }
        return delegate.deauthenticate()
            .flatMapLatest { _ -> ObservableSignal in
                AppContext.standard.updateUserMeta { $0.isLoggedIn = false }
            }
            .flatMapLatest { [weak self] _ -> ObservableSignal in
                self?.authState.onNext(.unauthenticated)
                AppContext.current = AppContext.standard
                KitLogger.info("Log out success, switching context to the StandardAppContext.")
                return .signal
            }
    }
    
    // MARK: - Data Center
    
    /// Each AppContext have a specific Store for storing data relevant to this context.
    public lazy var store: Store = try! Store(appContext: self)
    
    /// Convinience method for get persistance datasource in the Store.
    public var persist: ObservableDataBase { return store.persistance }
    
    /// Convinience method for get the cache datasource in the Store.
    public var cache: ObservableDataBase { return store.cache }
    
    /// Convinience method for get memory datasource in the Store.
    public var memory: ObservableDataBase { return store.memory }
    
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
