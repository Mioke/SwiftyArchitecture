//
//  Constants.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 28/06/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit

public struct Constants {
    public static let defaultDomain = "swiftyarchitecture.default"
    public static let networkingDomain = "swiftyarchitecture.networking"
}

extension Constants {
    public static let kitName = "MIOSwiftyArchitecture"
}

internal func todo_error() -> NSError {
    return NSError(domain: "", code: 777, userInfo: nil)
}
