//
//  UserService.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/24.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

class UserService: KMBaseServise {
    
    // Singleton
    static let sharedInstance = UserService()
    
    func login() -> Bool {
        
        let url = "http://115.29.175.210:8009/auth/login/?os=iphone"
        let param = [
            "ver": "i5.1.1",
            "account": "1223@ss.com",
            "password": "111111",
            "device": "12345"
        ]
        let result = self.sendRequestOfURLString(url, param: param, timeout: nil)
        
        print(result)
        
        if result.isSuccess() {
            if result.successData()!["success"] as? Int == 0 { return false }
        }
        else { return false }
        
        return true
    }

}
