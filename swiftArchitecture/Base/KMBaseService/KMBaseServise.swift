//
//  KMBaseServise.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import AFNetworking

class KMBaseServise: NSObject {
    
    
}

extension KMBaseServise: NetworkManagerProtocol {
    
    typealias returnType = [String: AnyObject]

    func sendRequestOfURLString(urlString: String, param: [String : AnyObject]?, timeout: NSTimeInterval?) -> ResultType<returnType> {
        
        guard let url = NSURL(string: urlString) else {
            return ResultType.Failed(ErrorResultType(description: "URL error", code: 003))
        }
        
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

        var result: ResultType<returnType> = ResultType.Failed(ErrorResultType(description: "No data", code: 001))
        
        let operation = AFHTTPRequestOperation(request: request)
        operation.start()
        operation.waitUntilFinished()
        
        if let resp = operation.responseData {
            do {
                let dic = try NSJSONSerialization.JSONObjectWithData(resp, options: .AllowFragments) as! returnType
                result = ResultType.Success(dic)
            } catch {
                result = ResultType.Failed(ErrorResultType(description: "JSON data parse error", code: 000))
            }
        }
        return result
    }
}