//
//  KMRequestGenerator.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import Alamofire

/// Generator of reuqest
public class KMRequestGenerator: NSObject {
    
    /// Session configuration for default HTTP request
    public static var defaultConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        return configuration
    }()
    
    private static var defaultManager: SessionManager {
        return SessionManager(configuration: defaultConfiguration)
    }
    
    /// Session configurtion for default HTTPS request
    private static var httpsConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        
        return configuration
    }
    
    /// Default session manager for HTTPs request, you can change it for customized
    public static var httpsManager: SessionManager = {
        return SessionManager(configuration: httpsConfiguration)
    }()
    
    public class func generateRequest(
        withApi api: BaseApiManager,
        method: HTTPMethod,
        params: [String: Any]?,
        encoding: ParameterEncoding = URLEncoding.default) -> DataRequest {
        
        guard let child = api as? ApiInfoProtocol else {
            fatalError("API: \(api) must conform to protocol ApiInfoProtocol")
        }
        
        let manager = child.server.isHTTPs ? httpsManager : defaultManager
        manager.session.configuration.timeoutIntervalForRequest = api.timeoutInterval
        
        let req = manager.request(api.apiURLString,
                                  method: method,
                                  parameters: params,
                                  encoding: encoding,
                                  headers: api.HTTPHeaders)
        
        // FIXME: Do additional configuration or signature etc.
        SystemLog.write("Send request:\n\tRequest Info:\(req.description)\n\tRequest Headers:\(req.request?.allHTTPHeaderFields ?? [:])\n\tParam:\(params ?? [:])")
        
        return req
    }
}
