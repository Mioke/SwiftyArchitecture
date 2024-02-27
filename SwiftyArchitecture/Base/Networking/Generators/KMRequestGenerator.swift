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
    public static var defaultManager: Alamofire.Session = {
        return Alamofire.Session(configuration: defaultConfiguration)
    }()
    
    /// Default session manager for HTTPs request, you can change it for customized
    public static var httpsManager: Alamofire.Session = {
        return Alamofire.Session(configuration: httpsConfiguration)
    }()
    
    public class func generateRequest<T: ApiInfoProtocol>(
        withApi api: API<T>,
        params: T.RequestParam?) async throws -> DataRequest {
            
            let manager = T.server.supportHTTPS ? httpsManager : defaultManager
            manager.session.configuration.timeoutIntervalForRequest = await api.state.timeoutInterval
            
            var parameters: Parameters? = nil
            if let params = params {
                let data = try JSONEncoder().encode(params)
                parameters = try JSONSerialization.jsonObject(with: data, options: []) as? Parameters
            }
            
            let req = manager.request(api.apiURL,
                                      method: T.httpMethod,
                                      parameters: parameters,
                                      encoding: T.encoding,
                                      headers: api.HTTPHeaders)
            
            // TODO: Do additional configuration or signature etc.
            KitLogger.log(
                level: .info,
                message: "Send request:\n\tRequest Info:\(req.description)\n\tRequest Headers:\(req.request?.allHTTPHeaderFields ?? [:])\n\tParam:\(parameters ?? [:])")
            
            return req
        }
}
