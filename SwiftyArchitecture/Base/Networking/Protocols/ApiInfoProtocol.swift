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
 - attention: `apiVersion` and `apiName` __shouldn't begin and end with '/'__. Just like "v2", "user/login" is good. If you don't have a versioned-API, return an empty string.
 */
public protocol ApiInfoProtocol: AnyObject {
    
    /// The version of api
    static var apiVersion: String { get }
    
    /// The name of api
    static var apiName: String { get }
    
    /// The HTTP method of this api
    static var httpMethod: Alamofire.HTTPMethod { get }
    
    /// The server for this api to request
    static var server: Server { get }
    
    /// Max counts of auto retry machanism, you can return different counts for different error.
    ///
    /// - Parameter code: Error's code
    /// - Returns: Counts of auto retry machanism, return `nil` to disable the machanism.
    static func autoRetryMaxCount(withErrorCode code: Int) -> Int?
    
    /// The time of retry interval between two request.
    ///
    /// - Parameter code: Error's code
    /// - Returns: Time interval for the error, return `nil` will use default value `0`.
    static func retryTimeInterval(withErrorCode code: Int) -> UInt64?
    
    /// HTTP headers of request
    ///
    /// - Returns: HTTP headers
    static func headers() -> Alamofire.HTTPHeaders?
    
    /// Encoding function of api's parameters, default is `Alamofire.URLEncoding.default`(aka `methodDependent`)
    static var encoding: Alamofire.ParameterEncoding { get }
    
    associatedtype RequestParam: Codable
    
    associatedtype ResultType
    /// Response serializer type, default is .JSON, that request will call `responseJSON` method when get response.
    static var responseSerializer: ResponseSerializer<ResultType> { get }
}

extension ApiInfoProtocol {
    
    public static func autoRetryMaxCount(withErrorCode code: Int) -> Int? {
        return nil
    }
    
    public static func retryTimeInterval(withErrorCode code: Int) -> UInt64? {
        return nil
    }
    
    public static func headers() -> Alamofire.HTTPHeaders? {
        return nil
    }
    
    public static var encoding: Alamofire.ParameterEncoding {
        return URLEncoding.default
    }
}
