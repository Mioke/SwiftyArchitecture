//
//  KMPersistance.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/1.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

protocol PersistanceManagerProtocol: NSObjectProtocol {
    
}

protocol DatabaseManagerProtocol: PersistanceManagerProtocol {
    
    var path: String { get set }
    
    var database: FMDatabaseQueue { get set }
    var databaseName: String { get set }
    
    init(path: String, DBName: String)
}

class KMPersistanceDatabase: NSObject {
    
    private weak var child: protocol<DatabaseManagerProtocol>?
    
    override init() {
        super.init()
        
        if self is protocol<DatabaseManagerProtocol> {
            self.child = self as? protocol<DatabaseManagerProtocol>
            assert(self.child != nil, "KMPersistanceDatabase's database couldn't be nil")
        } else {
            assert(false, "KMPersistanceDatabase's subclass must follow the KMPersistanceProtocol")
        }
    }
    
    /**
     Test function, use subclass's params for some public functions
     
     - parameter query: query SQL string
     - parameter args:  the args in SQL string
     
     - returns: result array
     */
    func query(query: String, withArgumentsInArray args: [AnyObject]?) -> NSMutableArray {
        return DatabaseManager.database(self.child!.database, query: query, withArgumentsInArray: args)
    }
}
