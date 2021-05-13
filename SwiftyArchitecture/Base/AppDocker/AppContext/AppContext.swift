//
//  AppContext.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit

public let kAppContextChangedNotification = NSNotification.Name.init(rawValue: "kAppContextChangedNotification")

public class AppContext: NSObject {
    
    public static var current = DefaultAppContext() {
        didSet {
            guard oldValue != current else { return }
            NotificationCenter.default.post(name: kAppContextChangedNotification, object: current)
        }
    }

    public var currentUserId: String
    public var db: RealmDataBase!
    public var dataCenter: DataCenter!
    
    public init(with userId: String) {
        self.currentUserId = userId
        super.init()
        
        self.db = try! RealmDataBase(appContext: self)
        self.dataCenter = DataCenter(appContext: self)
    }
    
    deinit {
        self.db.realm.invalidate()
    }
}

final public class DefaultAppContext: AppContext {
    
    init() {
        super.init(with: "__empty_user_id__")
    }
}
