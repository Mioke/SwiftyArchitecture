//
//  AppDockerConstants.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/2/17.
//

import Foundation

public let AppDockerDomain = "com.mioke.appdocker"

public struct AppDockerError {
    static let noDelegateError: NSError = error(code: .noDelegateError, message: .noDelegate)
}

public enum AppDockerErrorCode: Int {
    case noDelegateError = 1
}

public enum AppDockerErrorMessage: String {
    case noDelegate = "The delegate of this function hasn't been set yet."
}

// MARK: - Convenience & Private

func error(code: AppDockerErrorCode, message: AppDockerErrorMessage) -> NSError {
    return .init(
        domain: AppDockerDomain,
        code: code.rawValue,
        userInfo: [NSLocalizedDescriptionKey: message]
    )
}
