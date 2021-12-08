//
//  AppContext.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit
import RealmSwift

public let kAppContextChangedNotification = NSNotification.Name(rawValue: "kAppContextChangedNotification")

public class AppContext: NSObject {
    
    public static let standard = DefaultAppContext()
    public static var current = standard {
        didSet {
            guard oldValue != current else { return }
            NotificationCenter.default.post(name: kAppContextChangedNotification, object: current)
        }
    }

    public var currentUserId: String
    public var dataCenter: DataCenter!
    
    public init(with userId: String) {
        self.currentUserId = userId
        super.init()
        self.dataCenter = DataCenter(appContext: self)
    }
}

final public class DefaultAppContext: AppContext {
    
    init() {
        super.init(with: "__standard__")
    }
}

// MARK: - Convenience
public func AppContextCurrentDatabase() -> Realm {
    return AppContext.current.dataCenter.db.realm
}

public func AppContextCurrentMemory() -> Realm {
    return AppContext.current.dataCenter.memory.realm
}
