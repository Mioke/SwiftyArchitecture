//
//  Constants.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 28/06/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit
import SwiftUI

public struct Consts {
    public static let defaultDomain = "com.mioke.swiftyarchitecture.default"
    public static let networkingDomain = "com.mioke.swiftyarchitecture.networking"
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
    
    static func error(domain: String, info: KitErrors.Info) -> NSError {
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
        case todo = 777
        
        // networking
        case responseError = 1000
        case apiConstructionFailed
        
        // persistance
        
        // app docker
        
        // componentize
        case graphCycle = 4000
    }
}


// Demo
public extension KitErrors {
    static var todoInfo: Info {
        .init(code: .todo, message: "The author is too lazy to complete this.")
    }
    static let todo: NSError = error(domain: Consts.defaultDomain, info: KitErrors.todoInfo)
    
    
    static var unknownErrorInfo: Info {
        return .init(code: .unknown, message: "Unknown error")
    }
    
    static var unknown: NSError {
        return error(domain: Consts.networkingDomain, info: unknownErrorInfo)
    }
}

