//
//  ApiLogin.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

class ApiLogin: BaseApiManager, ApiInfoProtocol {

    // MARK: ApiInfoProtocol params
    
    var apiVersion: String {
        get {
            return ""
        }
    }
    var apiName: String {
        get {
            "auth/login/?os=iphone/"
        }
    }
    var server: Server {
        get {
            return kServer
        }
    }
}
