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
            return ResultType.Failed(ErrorResultType(description: "URL error", code: 1003))
        }
        
        let operation = NetworkManager.sendRequestOfURL(url, method: "POST", param: param, timeout: timeout)
        
        var result: ResultType<returnType> = ResultType.Failed(ErrorResultType(description: "No data", code: 1001))
        
        if let resp = operation.responseData {
            do {
                let dic = try NSJSONSerialization.JSONObjectWithData(resp, options: .AllowFragments) as! returnType
                result = ResultType.Success(dic)
            } catch {
                result = ResultType.Failed(ErrorResultType(description: "JSON data parse error", code: 1000))
            }
        }
        return result
    }
}