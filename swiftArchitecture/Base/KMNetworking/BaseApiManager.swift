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
    
    // MARK: Statics
    static let successKey = "success"
    static let successValue = 1
    
    // MARK: Privates
    private weak var child: ApiInfoProtocol?
    private var request: Request?
    
    private var data: [String: AnyObject]?
    private var urlString: String?
    
    // MARK: Publics
    var isLoading = false
    var timeoutInterval: NSTimeInterval = 20
    var shouldAutoCacheResultWhenSucceed: Bool = false
    
    // MARK: Initialization
    override init() {
        super.init()
        if self is ApiInfoProtocol {
            self.child = (self as! ApiInfoProtocol)
        } else {
            assert(false, "ApiManager's subclass must conform the ApiInfoProtocol")
        }
    }
    
    // MARK: - Actions
    weak var delegate: ApiCallbackProtocol?
    
    func loadDataWithParams(params: [String: AnyObject]) -> Void {
        
        if self.isLoading {
            return
        }
        // If there is cached result then return it.
        if self.shouldAutoCacheResultWhenSucceed,
            let value = NetworkCache.memoryCache.objectForKey(self.apiURLString()) as? [String: AnyObject] {
                self.data = value
                self.loadingComplete()
                self.delegate?.ApiManager(self, finishWithOriginData: value)
                return
        }
        
        self.isLoading = true
        self.cancel()
        
        self.request = KMRequestGenerator.generateRequestWithAPI(self, method: self.child!.httpMethod, params: params)
        self.request?.session.configuration.timeoutIntervalForRequest = self.timeoutInterval
        
        self.request?.responseJSON { (resp: Response<AnyObject, NSError>) -> Void in
            
            self.isLoading = false
            
            if let value = resp.result.value as? [String: AnyObject] {
                
                SystemLog.write("HTTP response:\n\tRESP:\(resp.response!)\n\tVALUE:\(value)")
                
                self.data = value
                self.loadingComplete()
                
                // FIXME: Change the type of successValue conform to Server's return value type.
                if value[BaseApiManager.successKey] as! Int == BaseApiManager.successValue {
                    self.delegate?.ApiManager(self, finishWithOriginData: value)
                    if self.shouldAutoCacheResultWhenSucceed {
                        NetworkCache.memoryCache.setObject(value, forKey: self.child!.apiName)
                    }
                } else {
                    // TODO: The error that server's return
//                    self.delegate?.ApiManager(self, failedWithError: <#T##NSError#>)
                }
            }
            else if let error = resp.result.error {
                self.loadingFailedWithError(error)
                self.delegate?.ApiManager(self, failedWithError: error)
                
                SystemLog.write("HTTP response:\n\tRESP:\(resp.response!)\n\tVALUE:\(error)")
            }
            else {
                let error = NSError(domain: "Unknown domain", code: 1001, userInfo: nil)
                self.loadingFailedWithError(error)
                self.delegate?.ApiManager(self, failedWithError: error)
                
                SystemLog.write("HTTP response:\n\tRESP:\(resp.response!)\n\tVALUE:\(error)")
            }
        }
    }
    
    func cancel() -> Void {
        self.request?.cancel()
    }
    
    // MARK: - Callbacks
    func loadingComplete() -> Void {
        
        // do nothing
    }
    
    func loadingFailedWithError(error: NSError) -> Void {
        // TODO: Do something with general error like `if error.code == 1001 { ... }`

    }
    
    // MARK: - Others
    func isSuccess() -> Bool {
        return self.data != nil && !self.isLoading
    }
    
    func originData() -> [String: AnyObject]? {
        return self.data
    }
    
    func apiURLString() -> String {
        
        if self.urlString == nil {
            if self.child!.apiVersion.isEmpty {
                self.urlString = self.child!.server.url + "/" + self.child!.apiName
            } else {
                self.urlString = self.child!.server.url + "/" + self.child!.apiVersion + "/" + self.child!.apiName
            }
        }
        return self.urlString!
    }
}
