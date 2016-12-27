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
    
    /// For produce the unique key of caches
    fileprivate static var keyNum: Int = 0
    
    // MARK: Privates
    fileprivate weak var child: ApiInfoProtocol?
    fileprivate var request: DataRequest?
    
    fileprivate var retryTimes: Int = 0
    fileprivate var shouldAutoRetry: Bool = true
    fileprivate var autoProcessServerData: Bool = true
    
    fileprivate var data: [String: AnyObject]?
    fileprivate var urlString: String?
    fileprivate var cacheKey: String?
    
    // MARK: Publics
    var isLoading = false
    var timeoutInterval: TimeInterval = 20
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
    
    func loadData(with params: [String: AnyObject]) -> Void {
        
        if self.isLoading {
            return
        }
        // If there is cached result then return it.
        
        if let key = self.cacheKey,
            let value = NetworkCache.memoryCache.objectForKey(key) as? [String: AnyObject], self.shouldAutoCacheResultWhenSucceed {
            
            self.data = value
            self.loadingComplete()
            self.delegate?.ApiManager(self, finishWithOriginData: value as AnyObject)
            return
        }
        
        self.isLoading = true
        self.cancel()
        
        self.request = KMRequestGenerator.generateRequest(with: self, method: self.child!.httpMethod, params: params)
        self.request?.session.configuration.timeoutIntervalForRequest = self.timeoutInterval
        
        self.request?.responseJSON(completionHandler: { (resp: DataResponse<Any>) in
            
            self.isLoading = false
            var err: NSError?
            
            // HTTP request success
            if let value = resp.result.value as? [String: AnyObject] {
                self.data = value
                SystemLog.write("HTTP response:\n\tRESP:\(resp.response!)\n\tVALUE:\(value)" as AnyObject?)
                
                // If the server has retry mechanism
                if let server = self.child!.server as? ServerDataProcessProtocol,
                    self.autoProcessServerData {
                    
                    var shouldRetry = false
                    do {
                        try server.handle(value as AnyObject, shouldRetry: &shouldRetry)
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
                self.loadingFailed(with: error as NSError)
                err = error as NSError?
            }
            // Value is not a Dictionary
            else {
                let error = NSError(domain: "Unknown domain", code: 1001, userInfo: nil)
                self.loadingFailed(with: error)
                err = error
            }
            
            if let err = err {
                // Retry operations
                if let maxCount = self.child!.autoRetryMaxCount(withErrorCode: err.code),
                    let interval = self.child!.retryTimeInterval(withErrorCode: err.code) {
                    
                    if self.shouldAutoRetry && self.retryTimes < maxCount {
                        
                        DispatchQueue.global(qos: .default).asyncAfter(deadline: DispatchTime(uptimeNanoseconds: interval), execute: {
                            self.loadData(with: params)
                        })
                        self.retryTimes += 1
                        return
                    }
                }
                self.retryTimes = 0
                self.doOnMainQueue({
                    self.delegate?.ApiManager(self, failedWithError: err)
                })
                SystemLog.write("HTTP response:\n\tRESP:\(resp.response!)\n\tVALUE:\(err)" as AnyObject?)
            }
        })
    }
    
    func cancel() -> Void {
        self.request?.cancel()
    }
    
    // MARK: - Callbacks
    func loadingComplete() -> Void {
        
        self.doOnMainQueue({
            self.delegate?.ApiManager(self, finishWithOriginData: self.data! as AnyObject)
        })
        self.retryTimes = 0
        if self.shouldAutoCacheResultWhenSucceed {
            if self.cacheKey == nil {
                self.cacheKey = "\(self.child!.apiName)_\(BaseApiManager.keyNum)"
                BaseApiManager.keyNum += 1
            }
            NetworkCache.memoryCache.set(object: self.data!, forKey: self.child!.apiName)
        }
    }
    
    func loadingFailed(with error: NSError) -> Void {
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
    
    func doOnMainQueue(_ block: @escaping ()->()) -> Void {
        DispatchQueue.main.async(execute: block)
    }
}
