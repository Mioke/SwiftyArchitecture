//
//  ApiLogin.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import Alamofire

class ApiLogin: BaseApiManager, ApiInfoProtocol {

    // MARK: - ApiInfoProtocol params
    
    var apiVersion: String {
        get { return "" }
    }
    var apiName: String {
        get { return "auth/login/?os=iphone/" }
    }
    var server: Server {
        get { return kServer }
    }
    var httpMethod: Alamofire.Method {
        get { return .GET }
    }
    
    // If you want to do custom options, override the init().
    override init() {
        super.init()
        // like this, the default setting of this option is false, you can change it when super.init() is done.
        self.shouldAutoCacheResultWhenSucceed = true
    }
    
    // MARK: - Completion
    override func loadingComplete() {
        super.loadingComplete()
        
        Log.debugPrintln(self.originData())
    }
    override func loadingFailedWithError(error: NSError) {
        Log.debugPrintln(error)
    }
}
