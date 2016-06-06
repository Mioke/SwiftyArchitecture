//
//  DefaultDatabase.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/1.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import FMDB

class DefaultDatabase: KMPersistanceDatabase, DatabaseManagerProtocol {
    
    static var instance: KMPersistanceDatabase = DefaultDatabase()
    
    var path: String
    var database: FMDatabaseQueue
    var databaseName: String

    override init() {

        self.databaseName = "default.db"
        self.path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! + "/" + self.databaseName
        self.database = FMDatabaseQueue(path: self.path)
        
        super.init()
    }
}
