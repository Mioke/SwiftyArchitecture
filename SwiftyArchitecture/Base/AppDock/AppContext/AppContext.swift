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

    // MARK: - User
    public internal(set) var user: UserProtocol
    
    public var userId: String {
        return user.id
    }
    
    public init(user: UserProtocol) {
        self.user = user
        super.init()
    }
    
    public static var authController: AuthController = .init(delegate: nil)
    
    /// Start a new app context.
    /// - Parameter user: the user of this context.
    public static func startAppContext(with user: UserProtocol) -> Void {
        let appContext = AppContext(user: user)
        if let value = user.authState.value, value != .authenticated {
            user.authState.onNext(.authenticated)
        }
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
    public lazy var store: Store = Store(appContext: self)
}

// MARK: - Convenience
public func AppContextCurrentDatabase() -> Realm {
    return AppContext.current.store.db.realm
}

public func AppContextCurrentMemory() -> Realm {
    return AppContext.current.store.memory.realm
}
