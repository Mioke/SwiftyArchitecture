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
 - attention: `apiVersion` and `apiName` __shouldn't begin and end with '/'__. Just like "v2", "user/login" is good. If you don't have a versioned-API, return an empty string is ok.
 */
public protocol ApiInfoProtocol: NSObjectProtocol {
    
    /// The version of api
    var apiVersion: String { get }
    
    /// The name of api
    var apiName: String { get }
    
    /// The HTTP method of this api
    var httpMethod: Alamofire.HTTPMethod { get }
    
    /// The server for this api to request
    var server: Server { get }
    
    /// Max counts of auto retry machanism, you can return different counts for different error.
    ///
    /// - Parameter code: Error's code
    /// - Returns: Counts of auto retry machanism
    func autoRetryMaxCount(withErrorCode code: Int) -> Int?
    
    /// The time of retry interval between two request
    ///
    /// - Parameter code: Error's code
    /// - Returns: Time interval for the error
    func retryTimeInterval(withErrorCode code: Int) -> UInt64?
}

extension ApiInfoProtocol {
    
    public func autoRetryMaxCount(withErrorCode code: Int) -> Int? {
        return nil
    }

    public func retryTimeInterval(withErrorCode code: Int) -> UInt64? {
        return nil;
    }
}
