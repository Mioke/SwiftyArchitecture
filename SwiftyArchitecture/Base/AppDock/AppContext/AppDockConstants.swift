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
}


