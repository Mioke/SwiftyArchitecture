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

let MioDemoServer: Server = .init(live: URL(string: "https://www.baidu.com")!,
                                  customEnvironments: [
                                    .custom("Dev"): URL(string: "https://www.baidu.com")!,
                                    .custom("Staging"): URL(string: "https://www.baidu.com")!,
                                  ])

struct EmptyRequestParam: Codable { }

class TestAPI: NSObject, ApplicationBasedApiInfoProtocol {
    typealias RequestParam = EmptyRequestParam
    typealias ResultType = TestAPI.Result
    
    static var apiVersion: String {
        get { return "" }
    }
    static var apiName: String {
        get { return "s" }
    }
    static var server: Server {
        get { return MioDemoServer }
    }
    static var httpMethod: Alamofire.HTTPMethod {
        get { return .get }
    }
    static func headers() -> HTTPHeaders? {
        return ["Cookie": "uid=123456"]
    }
}

extension TestAPI {
    
    struct Result: Codable {
        let isFinal: Bool
        let objects: [TestObj]
        
        enum CodingKeys: String, CodingKey {
            case isFinal = "is_final"
            case objects = "objs"
        }
    }
}
