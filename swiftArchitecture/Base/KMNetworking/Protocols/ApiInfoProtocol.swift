//
//  ApiInfoProtocol.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import Alamofire

/**
 *  Protocol that descripe what infomation should API provide,
 */
protocol ApiInfoProtocol: NSObjectProtocol {

    // Attention: apiVersion and apiName shouldn't begin and end with '/'. Just like "v2", "user/login" is good. If you don't have a versioned-API, return an empty string is ok.
    
    var apiVersion: String { get }
    var apiName: String { get }
    var httpMethod: Alamofire.HTTPMethod { get }
    
    var server: Server { get }
    
    func autoRetryMaxCount(withErrorCode code: Int) -> Int?
    func retryTimeInterval(withErrorCode code: Int) -> UInt64?
}

// Default setting
extension ApiInfoProtocol {
    
    func autoRetryMaxCount(withErrorCode code: Int) -> Int? {
        return nil
    }

    func retryTimeInterval(withErrorCode code: Int) -> UInt64? {
        return nil;
    }
}
