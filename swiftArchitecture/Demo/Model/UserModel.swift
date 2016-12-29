//
//  UserModel.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/2.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

class UserModel: NSObject, RecordProtocol {
    
    var userName: String
    var userID: Int
    
    init(name: String, uid: Int) {
        self.userName = name
        self.userID = uid
        
        super.init()
    }
    
    // MARK: - RecordProtocol delegate
    func dictionaryRepresentation(in table: TableProtocol) -> [String : Any]? {
        if table is UserTable {
            return [
                "user_name": self.userName,
                "user_id": self.userID
            ]
        }
        return nil
    }
}
