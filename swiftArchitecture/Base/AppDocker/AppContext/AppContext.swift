//
//  AppContext.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit

public class AppContext: NSObject {
    
    public static var current = DefaultAppContext()

    public var currentUserId: String
    public var db: RealmDataBase!
    public var dataCenter: DataCenter!
    
    public init(with userId: String) {
        self.currentUserId = userId
        super.init()
        
        self.db = try! RealmDataBase.init(with: self)
        self.dataCenter = DataCenter.init(with: self.db)
    }
}

public class DefaultAppContext: AppContext {
    
    init() {
        super.init(with: "__empty_user_id__")
    }
}