//
//  NetworkManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/26.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
//import AFNetworking

@available(iOS, unavailable, message: "Not supported now")
class NetworkManager: NSObject {

//    class func sendRequestOfURL(_ url: URL, method: String, param: [String : AnyObject]?, timeout: TimeInterval?) -> AFHTTPRequestOperation {
    
//        switch method {
//        case "POST":
//            return POST(url, param: param, timeout: timeout)
//        default:
//            return AFHTTPRequestOperation()
//        }
//    }
    
//    fileprivate class func POST(_ url: URL, param: [String : AnyObject]?, timeout: TimeInterval?) -> AFHTTPRequestOperation {
//        
//        let request = NSMutableURLRequest(url: url)
//        request.httpMethod = "POST"
//        request.timeoutInterval = timeout ?? 10
//        
//        if param != nil {
//            var bodyString = ""
//            for key in param!.keys {
//                bodyString += "&\(key)=\(param![key])"
//            }
//            bodyString = bodyString.substring(from: bodyString.characters.index(after: bodyString.startIndex))
//            request.httpBody = bodyString.data(using: String.Encoding.utf8)
//        }
//        
//        let operation = AFHTTPRequestOperation(request: request as URLRequest)
//        operation.start()
//        operation.waitUntilFinished()
//        
//        return operation
//    }
    
//    class func dealError(error: ErrorResultType) -> Void {
//        
//        // do something like
//        if error.code == 1001 {
//            // ...
//        }
//    }
}
