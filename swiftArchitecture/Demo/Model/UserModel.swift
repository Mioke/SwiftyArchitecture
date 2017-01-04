//
//  UserModel.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/2.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

class UserModel: NSObject, RecordProtocol {
    
    var userName: String = ""
    var userID: Int = 0
    
    convenience init(name: String, uid: Int) {
        self.init()
        
        self.userName = name
        self.userID = uid
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
    
    override required init() {
        super.init()
    }
    static func read(from dictionary: [AnyHashable: Any], table: TableProtocol) -> Self? {
        
        if table is UserTable {
            guard let uid = dictionary["user_id"] as? Int, let name = dictionary["user_name"] as? String else {
                return nil
            }
            // - Only use `self.init()` and must have a `required init()` that can return `Self` in this function
            // - Or mark this class as `final` and replace `Self` to Class name.
            // Both just fine now, but it's not cool, tring to find a perfect way to solve this problem.
            let model = self.init()
            model.userID = uid
            model.userName = name
            
            return model
        }
        return nil
    }
}
