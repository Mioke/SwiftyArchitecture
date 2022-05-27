//
//  TestAPI.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 29/12/2016.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit
import Alamofire
import MIOSwiftyArchitecture

class TestAPI: NSObject, ApiInfoProtocol {
    
    typealias ResultType = [String: Any]
    
    static var apiVersion: String {
        get { return "" }
    }
    static var apiName: String {
        get { return "s" }
    }
    static var server: Server {
        get { return Server(online: "http://www.baidu.com",
                            offline: "http://www.baidu.com") }
    }
    static var httpMethod: Alamofire.HTTPMethod {
        get { return .get }
    }
    static func headers() -> HTTPHeaders? {
        return ["Cookie": "uid=123456"]
    }
    
    static var responseSerializer: MIOSwiftyArchitecture.ResponseSerializer<[String : Any]> {
        return MIOSwiftyArchitecture.JSONResponseSerializer<[String : Any]>()
    }
}
