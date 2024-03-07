//
//  Constants.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 28/06/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit
import SwiftUI

@_exported import SwiftyArchitectureMacrosPackage

#if swift(<5.5.2)
#error("SwiftyArchitecture only support Swift version >= 5.5.2 for concurrency support purpose.")
#endif

public struct Consts {
    // - Domains
    /// The domain prefix of this framework, used in any identifier like networking, queue etc.
    public static let domainPrefix = "com.mioke.swiftyarchitecture"
    /// The global used or non-specific domain identifier.
    public static let defaultDomain = domainPrefix + ".default"
    /// The domain of networking kit in this kit.
    public static let networkingDomain = domainPrefix + ".networking"
    
    // - Time
    public static let milisecondsPerSecond: UInt64 = 1_000
    public static let microsecondsPerSecond: UInt64 = 1_000_000
    public static let nanosecondsPerSecond: UInt64 = 1_000_000_000
}

extension Consts {
    public static let kitName = "MIOSwiftyArchitecture"
}

internal func todo_error() -> NSError {
    return NSError(domain: "", code: 777, userInfo: nil)
}

public class KitErrors {
    
    public struct Info {
        let code: KitErrors.Codes
        let message: String?
    }
    
    public static func error(domain: String, info: KitErrors.Info) -> NSError {
        return .init(
            domain: domain,
            code: info.code.rawValue,
            userInfo: [NSLocalizedDescriptionKey: info.message ?? ""]
        )
    }
}

extension KitErrors {
    
    public enum Codes: Int {
        // general
        case noDelegate
        case unknown
        case deallocated
        case todo = 777
        
        // networking
        case responseError = 1000
        case apiConstructionFailed
        case inProgress
        
        // persistance
        case notFound = 2000
        
        // app dock
        case alreadyAuthenticated = 3000
        
        // componentize
        case graphCycle = 4000
    }
}


// MARK: - Intnernal errors

public extension KitErrors {
    
    private static var deallocatedInfo: Info {
        .init(code: .deallocated, message: "The instance has already been deallocated.")
    }
    static let deallocated: NSError = error(domain: Consts.defaultDomain, info: KitErrors.deallocatedInfo)
    
    private static var todoInfo: Info {
        .init(code: .todo, message: "The author is too lazy to complete this.")
    }
    static let todo: NSError = error(domain: Consts.defaultDomain, info: KitErrors.todoInfo)
    
    
    private static var unknownErrorInfo: Info {
        return .init(code: .unknown, message: "Unknown error")
    }
    
    static var unknown: NSError {
        return error(domain: Consts.networkingDomain, info: unknownErrorInfo)
    }
}

