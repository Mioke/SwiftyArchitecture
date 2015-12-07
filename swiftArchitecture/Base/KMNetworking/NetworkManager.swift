//
//  NetworkManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/26.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import AFNetworking

class NetworkManager: NSObject {

    class func sendRequestOfURL(url: NSURL, method: String, param: [String : AnyObject]?, timeout: NSTimeInterval?) -> AFHTTPRequestOperation {
        
        switch method {
        case "POST":
            return POST(url, param: param, timeout: timeout)
        default:
            return AFHTTPRequestOperation()
        }
    }
    
    private class func POST(url: NSURL, param: [String : AnyObject]?, timeout: NSTimeInterval?) -> AFHTTPRequestOperation {
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.timeoutInterval = timeout ?? 10
        
        if param != nil {
            var bodyString = ""
            for key in param!.keys {
                bodyString += "&\(key)=\(param![key])"
            }
            bodyString = bodyString.substringFromIndex(bodyString.startIndex.successor())
            request.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding)
        }
        
        let operation = AFHTTPRequestOperation(request: request)
        operation.start()
        operation.waitUntilFinished()
        
        return operation
    }
    
    class func dealError(error: ErrorResultType) -> Void {
        
        // do something like
        if error.code == 1001 {
            // ...
        }
    }
}
