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

protocol DataBaseManagerProtocol: PersistanceManagerProtocol {
    
    var path: String { get set }
    
    var database: FMDatabaseQueue { get set }
    var databaseName: String { get set }
    
    init(path: String, DBName: String)
}

class KMPersistance: NSObject {
    
    private weak var child: protocol<DataBaseManagerProtocol>?
    
    override init() {
        super.init()
        
        if !self.conformsToProtocol(DataBaseManagerProtocol.self as! Protocol) {
            assert(false, "KMPersistance's subclass must follow the KMPersistanceProtocol")
        } else {
            self.child = self as? protocol<DataBaseManagerProtocol>
        }
    }
}
