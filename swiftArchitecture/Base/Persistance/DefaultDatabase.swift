//
//  DefaultDatabase.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/1.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import FMDB

/// Default database
final public class DefaultDatabase: KMPersistanceDatabase, DatabaseManagerProtocol {
    
    public static let instance: KMPersistanceDatabase = DefaultDatabase()
    
    public var path: String
    public var database: FMDatabaseQueue
    public var databaseName: String

    public override init() {

        self.databaseName = "default.db"
        self.path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/" + self.databaseName
        self.database = FMDatabaseQueue(path: self.path) ?? FMDatabaseQueue()
        
        super.init()
    }
}
