//
//  Errors.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 16/06/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit

public class Errors: NSObject {
    
    public static var unknownError: NSError {
        return gennerate(with: -9999,
                         domain: Constants.networkingDomain,
                         message: "Unknown error")
    }
    
    public static var responseError: NSError {
        return gennerate(with: -1,
                         domain: Constants.networkingDomain,
                         message: "Unexpected response value")
    }
    
    public static var apiConstructionError: NSError {
        return gennerate(with: -2,
                         domain: Constants.networkingDomain,
                         message: "Unexpected API construction result")
    }

    private static func gennerate(with code: Int, domain: String, message: String) -> NSError {
        return NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
