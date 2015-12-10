//
//  UserTable.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/10.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

class UserTable: KMPersistanceTable, TableProtocol {
    
    weak var database: KMPersistanceDatabase? {
        get {
            return DefaultDatabase.instance
        }
    }
    
    var tableName: String {
        get {
            return "user_table"
        }
    }
    
    var tableColumnInfo: [String: String] {
        get {
            return [
                "user_id": "Integer primary key",
                "user_name": "text default NULL"
            ]
        }
    }
}
