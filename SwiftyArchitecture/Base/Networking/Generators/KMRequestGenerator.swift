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
    private static var defaultConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.af.default
        return configuration
    }
    
    /// Session configurtion for default HTTPS request
    private static var httpsConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.af.default
        return configuration
    }
    
    /// Default session manager for HTTP requests
    public static var defaultManager: Session = {
        return Session(configuration: defaultConfiguration)
    }()
    
    /// Default session manager for HTTPs request, you can change it for customized
    public static var httpsManager: Session = {
        return Session(configuration: httpsConfiguration)
    }()
    
    public class func generateRequest<T: ApiInfoProtocol>(
        withApi api: API<T>,
        params: [String: Any]?) throws -> DataRequest {
        
        let manager = T.server.isHTTPs ? httpsManager : defaultManager
        manager.session.configuration.timeoutIntervalForRequest = api.timeoutInterval
            
        let req = manager.request(api.apiURLString,
                                  method: T.httpMethod,
                                  parameters: params,
                                  encoding: T.encoding,
                                  headers: api.HTTPHeaders)
        
        // TODO: Do additional configuration or signature etc.
        SystemLog.write("Send request:\n\tRequest Info:\(req.description)\n\tRequest Headers:\(req.request?.allHTTPHeaderFields ?? [:])\n\tParam:\(params ?? [:])")
        
        return req
    }
}
