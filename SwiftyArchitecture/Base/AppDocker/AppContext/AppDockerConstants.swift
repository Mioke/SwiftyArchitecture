//
//  AppDockerConstants.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/2/17.
//

import Foundation

public let AppDockerDomain = "com.mioke.appdocker"

public struct AppDockerError {
    struct Info {
        let code: Int
        let message: String
    }
}

extension AppDockerError {
    private static var noDelegate: Info {
        .init(code: 1, message: "The delegate of this function hasn't been set yet.")
    }
    public static let noDelegateError: NSError = error(info: noDelegate)
}

// MARK: - Convenience & Private

func error(info: AppDockerError.Info) -> NSError {
    return .init(
        domain: AppDockerDomain,
        code: info.code,
        userInfo: [NSLocalizedDescriptionKey: info.message]
    )
}
