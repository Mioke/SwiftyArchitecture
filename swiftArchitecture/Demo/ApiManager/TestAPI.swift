//
//  TestAPI.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 29/12/2016.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit
import Alamofire

class TestAPI: API {
    // If you want to modify options, then override the init() function.
    override init() {
        super.init()
        // like this, this option of setting is false by default, but you can change it when super.init() is done.
        self.shouldAutoCacheResultWhenSucceed = true
    }
}

extension TestAPI: ApiInfoProtocol {
    var apiVersion: String {
        get { return "" }
    }
    var apiName: String {
        get { return "s" }
    }
    var server: Server {
        get { return Server(online: "http://www.baidu.com",
                            offline: "http://www.baidu.com") }
    }
    var httpMethod: Alamofire.HTTPMethod {
        get { return .get }
    }
    func headers() -> HTTPHeaders? {
        return ["Cookie": "uid=123456"]
    }
}
