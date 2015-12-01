//
//  DefaultDatabase.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/1.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

class DefaultDatabase: KMPersistance, DataBaseManagerProtocol {
    
    var path: String
    var database: FMDatabaseQueue
    var databaseName: String
    
    @available(*, unavailable, message="Use DefaultDatabse() instead")
    required convenience init(path: String, DBName: String) {
        self.init()
    }
    
    override init() {
        self.path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        self.databaseName = "default.db"
        self.database = FMDatabaseQueue(path: self.path + self.databaseName)
        
        super.init()
    }
}
