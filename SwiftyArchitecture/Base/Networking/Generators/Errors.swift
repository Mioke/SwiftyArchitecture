//
//  Errors.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 16/06/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit

extension KitErrors {
    
    static var responseErrorInfo: Info {
        return .init(code: .responseError, message: "Unexpected response value")
    }
    
    static var apiConstructionInfo: Info {
        return .init(code: .apiConstructionFailed, message: "Unexpected API construction result")
    }
    
    // Errors
    
    static var responseError: NSError {
        return error(domain: Consts.networkingDomain, info: responseErrorInfo)
    }
    
    static var apiConstructionError: NSError {
        return error(domain: Consts.networkingDomain, info: apiConstructionInfo)
    }
}
