//
//  UserTable.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/10.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

class UserTable: KMPersistanceTable, TableProtocol {
    
    var database: KMPersistanceDatabase {
        return DefaultDatabase.instance
    }
    
    var tableName: String {
        return "user_table"
    }
    
    var tableColumnInfo: [String: String] {
        return [
            "user_id": "Integer primary key",
            "user_name": "text default NULL"
        ]
    }
}
