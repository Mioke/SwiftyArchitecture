//
//  KMRequestGenerator.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import Alamofire

class KMRequestGenerator: NSObject {
    
    class func generateRequest(with api: BaseApiManager, method: HTTPMethod, params: [String: Any]?) -> DataRequest {
        
        let req = request(api.apiURLString(), method: method, parameters: params, encoding: URLEncoding.queryString, headers: nil)
//        let request = Manager.sharedInstance.request(method, api.apiURLString(), parameters: params, encoding: .URL, headers: nil)
        
        // FIXME: Do additional configuration or signature etc.
        Log.debugPrintln("\n==================================\nSend request:\n\tURL:\(api.apiURLString())\n\tparam:\(params)\n==================================\n")
        SystemLog.write("Send request:\n\tRequest Info:\(req.request!)\n\tParam:\(params)")
        
        return req
    }
}
