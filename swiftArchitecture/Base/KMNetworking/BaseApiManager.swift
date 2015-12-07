//
//  BaseApiManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

class BaseApiManager: NSObject {
    
    private weak var child: ApiInfoProtocol?
    
    private var result: ResultType<[String: AnyObject]>?
    
    var isLoading = false
    
    var timeoutInterval: NSTimeInterval = 20
    
    override init() {
        super.init()
        if self is ApiInfoProtocol {
            self.child = (self as! ApiInfoProtocol)
        } else {
            assert(false, "ApiManager's subclass must conform the ApiInfoProtocol")
        }
    }
    
    weak var delegate: ApiCallbackProtocol?
    
    func loadDataWithParams(params: [String: AnyObject]) -> Void {
        
    }
    
    func isSuccess() -> Bool {
        if let
            success = self.result?.successData()?["success"] as? String
            where success == "1"
        {
            return true
        }
        else {
            return false
        }
    }
    
    func originData() -> [String: AnyObject]? {
        return self.result?.successData()
    }
}
