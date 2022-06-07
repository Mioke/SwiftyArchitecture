//
//  AppDockerConstants.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/2/17.
//

import Foundation

public extension Consts {
    static let appDockerDomain = "com.mioke.swiftyarchitecture.appdocker"
}

public extension KitErrors {
    private static var noDelegate: Info {
        .init(code: .noDelegate, message: "The delegate of this function hasn't been set yet.")
    }
    static let noDelegateError: NSError = error(domain: Consts.appDockerDomain, info: noDelegate)
}


