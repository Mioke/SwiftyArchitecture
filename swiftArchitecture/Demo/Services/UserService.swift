//
//  UserService.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/24.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

class UserService: BaseService {
    
    // Singleton model
    static let currentUser = UserModel(name: "defaultUser", uid: 0)
    
    var user: UserModel {
        get { return UserService.currentUser }
    }
    
//    func login() throws -> Bool {
//        
//        let api = "auth/login/?os=iphone"
//        let param = [
//            "ver": "i5.1.1",
//            "account": "1223@ss.com",
//            "password": "111111",
//            "device": "12345"
//        ]
//        
//        let result = try self.sendRequestWithApiName(api, param: param, timeout: nil)
//        
//        print(result)
//        
//        if let success = result.successData()?["success"] as? Int where success == 1 {
//            return true
//        }
//        return false
//    }

}
