//
//  BaseApiManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import Alamofire

class BaseApiManager: NSObject {
    
    static let successKey = "success"
    static let successValue = 1
    
    private weak var child: ApiInfoProtocol?
    
    private var data: [String: AnyObject]?
    
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
        
        if self.isLoading {
            return
        }
        
        self.isLoading = true
        
        let request = KMRequestGenerator.generateRequestWithServer(self.child!.server, method: .GET, apiVersion: self.child!.apiVersion, apiName: self.child!.apiName, params: params)
        request.session.configuration.timeoutIntervalForRequest = self.timeoutInterval
        
        request.responseJSON { (resp: Response<AnyObject, NSError>) -> Void in
            
            self.isLoading = false
            
            if let value = resp.result.value as? [String: AnyObject] {
                self.data = value
                self.loadingComplete()
                
                // FIXME: Change the type of successValue conform to Server's return value type.
                if value[BaseApiManager.successKey] as! Int == BaseApiManager.successValue {
                    self.delegate?.ApiManager(self, finishWithOriginData: value)
                } else {
                    // TODO: The error that server's return
//                    self.delegate?.ApiManager(self, failedWithError: <#T##NSError#>)
                }
            }
            else if let error = resp.result.error {
                self.loadingFailedWithError(error)
                self.delegate?.ApiManager(self, failedWithError: error)
            }
            else {
                let error = NSError(domain: "Unknown domain", code: 1001, userInfo: nil)
                self.loadingFailedWithError(error)
                self.delegate?.ApiManager(self, failedWithError: error)
            }
        }
    }
    
    func loadingComplete() -> Void {
        // do nothing
    }
    
    func loadingFailedWithError(error: NSError) -> Void {
        // TODO: Do something with general error like `if error.code == 1001 { ... }`

    }
    
    func isSuccess() -> Bool {
        return self.data != nil && !self.isLoading
    }
    
    func originData() -> [String: AnyObject]? {
        return self.data
    }
}
