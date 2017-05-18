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
    
    public class func generateRequest(
        withApi api: BaseApiManager,
        method: HTTPMethod,
        params: [String: Any]?,
        encoding: ParameterEncoding = URLEncoding.default) -> DataRequest {
        
        let req = request(api.apiURLString, method: method, parameters: params, encoding: encoding, headers: api.HTTPHeaders)
        
        // FIXME: Do additional configuration or signature etc.
        SystemLog.write("Send request:\n\tRequest Info:\(req.description)\n\tRequest Headers:\(req.request?.allHTTPHeaderFields ?? [:])\n\tParam:\(params ?? [:])")
        
        return req
    }
}
