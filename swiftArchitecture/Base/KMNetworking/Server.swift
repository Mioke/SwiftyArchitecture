//
//  Server.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

/// Server model
open class Server: NSObject {
    
    /// Global setting, determine `Server` running in `DEBUG` or `RELEASE` mode(Usaully ;)).
    public static var online: Bool = true
    
    /// URL of online state
    public private(set) var onlineURL: String
    
    /// URL of offline state
    public private(set) var offlineURL: String
    
    /// Whether URL is a https url
    public private(set) var isHTTPs: Bool = false
    
    /// Current URL
    public var url: String {
        get {
            if Server.online {
                return self.onlineURL
            } else {
                return self.offlineURL
            }
        }
    }
    /**
     Initailize a server with online url and offline/test url
     
     - attention: Format is something like _https://10.24.0.3:8001_, don't end with '/' (I think this is big enough to warn you)
     
     - parameter online:  The URL that online server's site
     - parameter offline: The URL that offline or test server's site
     */
    public init(online: String, offline: String) {
        self.onlineURL = online
        self.offlineURL = offline
        super.init()
        
        if let first = url.components(separatedBy: "/").first {
            isHTTPs = first.lowercased().contains("https")
        }
    }
}

/// Customize data process operation of server
public protocol ServerDataProcessProtocol {
    func handle(data: Any) throws -> Void
}
