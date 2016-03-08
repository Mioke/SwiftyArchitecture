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
    
    class func generateRequestWithAPI(api: BaseApiManager, method: Alamofire.Method, params: [String: AnyObject]) -> Request {
        
        let request = Manager.sharedInstance.request(method, api.apiURLString(), parameters: params, encoding: .URL, headers: nil)
        
        // FIXME: Do additional configuration or signature etc.
        Log.debugPrintln("\n==================================\nSend request:\n\tURL:\(api.apiURLString())\n\tparam:\(params)\n==================================\n")
        SystemLog.write("Send request:\n\tRequest Info:\(request.request!)\n\tParam:\(params)")
        
        return request
    }
}
