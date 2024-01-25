//
//  AppDockConstants.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/2/17.
//

import Foundation

public extension Consts {
    static let appDockDomain = "com.mioke.swiftyarchitecture.appdock"
}

public extension KitErrors {
    private static var noDelegate: Info {
        .init(code: .noDelegate, message: "The delegate of this function hasn't been set yet.")
    }
    static let noDelegateError: NSError = error(domain: Consts.appDockDomain, info: noDelegate)
    
    
    private static var alreadyAuthenticatedInfo: Info {
        return .init(code: .alreadyAuthenticated, message: "AppContext already in a custom user context, can't authenticate a new user now.")
    }
    
    static var alreadyAuthenticated : NSError {
        return error(domain: Consts.appDockDomain, info: alreadyAuthenticatedInfo)
    }
    
    private static var notFoundInfo: Info {
        .init(code: .notFound, message: "The record can't be found in Store.")
    }
    
    /// File or data record cannot be found in the sandbox or database.
    static var notFound: NSError {
        error(domain: Consts.appDockDomain, info: notFoundInfo)
    }
}


