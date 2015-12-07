//
//  Server.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

class Server: NSObject {
    
    static var online: Bool = true

    private var onlineURL: String = ""
    private var offlineURL: String = ""
    
    var url: String {
        get {
            if Server.online {
                return self.onlineURL
            } else {
                return self.offlineURL
            }
        }
    }
    
    init(online: String, offline: String) {
        super.init()
        self.onlineURL = online
        self.offlineURL = offline
    }
}

let kServer = Server(online: "http://115.29.175.210:8009/", offline: "http://115.29.175.210:8009/")

