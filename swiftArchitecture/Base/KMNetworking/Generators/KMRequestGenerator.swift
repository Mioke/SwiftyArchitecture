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
    
    class func generateRequestWithServer(server: Server, method: Alamofire.Method, apiVersion: String, apiName: String, params: [String: AnyObject]) -> Request {
        
        let urlString = "\(server.url)/\(apiVersion)/\(apiName)"
        
        return Manager.sharedInstance.request(method, urlString, parameters: params, encoding: .URL, headers: nil)
    }
}
