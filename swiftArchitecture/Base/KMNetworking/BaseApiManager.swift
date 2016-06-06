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
    private static var keyNum: Int = 0
    
    // MARK: Privates
    private weak var child: ApiInfoProtocol?
    private var request: Request?
    
    private var retryTimes: Int = 0
    private var shouldAutoRetry: Bool = true
    private var autoProcessServerData: Bool = true
    
    private var data: [String: AnyObject]?
    private var urlString: String?
    private var cacheKey: String?
    
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
        
        if let key = self.cacheKey,
            let value = NetworkCache.memoryCache.objectForKey(key) as? [String: AnyObject]
            where self.shouldAutoCacheResultWhenSucceed {
            
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
            var err: NSError?
            
            // HTTP request success
            if let value = resp.result.value as? [String: AnyObject] {
                self.data = value
                SystemLog.write("HTTP response:\n\tRESP:\(resp.response!)\n\tVALUE:\(value)")
                
                // If the server has retry mechanism
                if let server = self.child!.server as? ServerDataProcessProtocol
                    where self.autoProcessServerData {
                    
                    var shouldRetry = false
                    do {
                        try server.handleData(value, shouldRetry: &shouldRetry)
                        self.loadingComplete()
                    } catch {
                        err = error as NSError
                    }
                } else {
                    self.loadingComplete()
                }
            }
            // HTTP request error
            else if let error = resp.result.error {
                self.loadingFailedWithError(error)
                err = error
            }
            // Value is not a Dictionary
            else {
                let error = NSError(domain: "Unknown domain", code: 1001, userInfo: nil)
                self.loadingFailedWithError(error)
                err = error
            }
            
            if err != nil {
                // Retry operations
                if let maxCount = self.child!.autoRetryMaxCountWithErrorCode(err!.code),
                    let interval = self.child!.retryTimeIntervalWithErrorCode(err!.code) {
                    
                    if self.shouldAutoRetry && self.retryTimes < maxCount {
                        
                        dispatch_after(dispatch_time_t(interval * NSEC_PER_SEC), dispatch_get_global_queue(0, 0), {
                            self.loadDataWithParams(params)
                        })
                        self.retryTimes += 1
                        return
                    }
                }
                self.retryTimes = 0
                self.doOnMainQueue({
                    self.delegate?.ApiManager(self, failedWithError: err!)
                })
                SystemLog.write("HTTP response:\n\tRESP:\(resp.response!)\n\tVALUE:\(err!)")
            }
        }
    }
    
    func cancel() -> Void {
        self.request?.cancel()
    }
    
    // MARK: - Callbacks
    func loadingComplete() -> Void {
        
        self.doOnMainQueue({
            self.delegate?.ApiManager(self, finishWithOriginData: self.data!)
        })
        self.retryTimes = 0
        if self.shouldAutoCacheResultWhenSucceed {
            if self.cacheKey == nil {
                self.cacheKey = "\(self.child!.apiName)_\(BaseApiManager.keyNum)"
                BaseApiManager.keyNum += 1
            }
            NetworkCache.memoryCache.setObject(self.data!, forKey: self.child!.apiName)
        }
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
    
    func doOnMainQueue(block: dispatch_block_t) -> Void {
        dispatch_async(dispatch_get_main_queue(), block)
    }
}
