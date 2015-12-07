//
//  KMBaseServise.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import AFNetworking

private let successKey = "success"
private let errorKey = "error"

//protocol ApiManagerDelegate: NSObjectProtocol {
//    
//    func managerDidFinishWithData(data: AnyObject)
//    func managerDidFinishWithError(error: ErrorResultType)
//}

class KMBaseService: NSObject {
    
//    weak var delegate: ApiManagerDelegate?
}

extension KMBaseService: NetworkManagerProtocol {
    
    typealias returnType = [String: AnyObject]
    
    var server: String {
        get {
            return kServer.url
        }
    }
    
    func sendRequestWithApiName(apiName: String, param: [String : AnyObject]?, timeout: NSTimeInterval?) throws -> ResultType<returnType> {
        
        guard let url = NSURL(string: self.server + apiName) else {
            throw ErrorResultType(desc: "URL error", code: 1003)
        }
        
        let operation = NetworkManager.sendRequestOfURL(url, method: "POST", param: param, timeout: timeout)
        
        var result: ResultType<returnType> = ResultType.Failed(ErrorResultType(desc: "No data", code: 1001))
        
        if let resp = operation.responseData {
            do {
                let dic = try NSJSONSerialization.JSONObjectWithData(resp, options: .AllowFragments) as! returnType

                if let success = dic[successKey] as? Int where success == 1 {
                    result = ResultType.Success(dic)
                }
                else if let errorDic = dic[errorKey] as? [String: String] {
                    
                    let code = Int(errorDic["code"] ?? "0")  ?? 1004
                    let msg = errorDic["msg"] ?? "Unknown error"
                    
                    result = ResultType.Failed(ErrorResultType(desc: msg , code: code))
                }
            } catch {
                result = ResultType.Failed(ErrorResultType(desc: "JSON data parse error", code: 1000))
            }
        }
        if let error = result.error() {
            throw error
        }
        return result
    }
}