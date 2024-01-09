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
    
    /// The environment model, describe different running environment of the same server logic.
    public enum Environment: Hashable {
        case live
        case custom(String)
    }
    
    /// Initiate configuration of a server.
    public struct Configuration {
        public let liveURL: URL
        public var customURLs: [Server.Environment: URL]
    }
    
    /// The current environment option for this server.
    public private(set) var currentEnvironment: Server.Environment = .live {
        didSet {
            if oldValue != currentEnvironment {
                // need notification?
            }
        }
    }
    
    var configuratoin: Server.Configuration
    
    public init(configuation: Server.Configuration) {
        self.configuratoin = configuation
    }
    
    /// Get the url of current environment.
    public var url: URL {
        switch currentEnvironment {
        case .live:
            return configuratoin.liveURL
        case .custom(_):
            return configuratoin.customURLs[currentEnvironment]!
        }
    }
    
    public func `switch`(to customID: String) throws {
        let newEnv = Environment.custom(customID)
        guard let _ = configuratoin.customURLs[newEnv] else {
            throw todo_error()
        }
        currentEnvironment = newEnv
    }
    
    public func `switch`(to env: Server.Environment) throws {
        guard env == .live || configuratoin.customURLs[env] != nil else {
            throw todo_error()
        }
        currentEnvironment = env
    }
    
}

/// Customize data process operation of server
public protocol ServerDataProcessProtocol {
    
    /// Handle the error data that may can handled uniformly. This function will be only called when the request data
    /// can't serialized to the type it expected.
    ///
    /// - Important: Only throw a error when the server can handle it.
    /// - Parameter data: The original response data.
    func handle(data: Data) throws -> Void
}

extension Server {
    
    /// Whether current environment support HTTPS, judged by the scheme of url is `https`.
    var supportHTTPS: Bool {
        self.url.scheme?.lowercased().contains("https") ?? false
    }
}

extension Server {
    
    /// Initialize method.
    /// - Parameters:
    ///   - live: The server url of live environment.
    ///   - customEnvironments: Custom environments urls.
    public convenience init(live: URL, customEnvironments: [Server.Environment: URL]) {
        let configuation: Server.Configuration = .init(liveURL: live, customURLs: customEnvironments)
        self.init(configuation: configuation)
    }
}
