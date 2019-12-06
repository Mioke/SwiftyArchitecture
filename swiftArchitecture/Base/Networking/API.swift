//
//  BaseApiManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import Alamofire

/// Concrete class of api manager, subclass from this class to use it and don't use this class directly.
open class API: NSObject {
    
    // MARK: Statics
    /// For produce the unique key of caches
    fileprivate static var keyNum: Int = 0
    
    // MARK: Privates
    fileprivate weak var child: ApiInfoProtocol?
    fileprivate var request: DataRequest?
    
    fileprivate var retryTimes: Int = 0
    
    fileprivate var data: [String: Any]?
    fileprivate var params: [String: Any]?
    fileprivate var urlString: String?
    fileprivate var cacheKey: String?
    fileprivate var defaultDelegate: ApiDelegate
    
    // MARK: Publics
    
    /// Request is out-going and not receive the response, that means `YES`.
    public var isLoading = false
    
    /// Interval for request timeout
    public var timeoutInterval: TimeInterval = 20
    
    /// Whether process the reponse data from server.
    public var autoProcessServerData: Bool = true
    
    /// If this property is true, it will auto retry when all situations are eligible
    public var shouldAutoRetry: Bool = true
    
    /// As property name says
    public var shouldAutoCacheResultWhenSucceed: Bool = false
    
    // MARK: Initialization
    public override init() {
        defaultDelegate = ApiDelegate()
        super.init()
        if self is ApiInfoProtocol {
            self.child = (self as! ApiInfoProtocol)
            delegate = defaultDelegate
        } else {
            assert(false, "ApiManager's subclass must conform the ApiInfoProtocol")
        }
    }
    
    // MARK: - Actions
    
    /// Callback delegate, for receiving response.
    public weak var delegate: ApiCallbackProtocol?
    
    /// Send request (for GET, POST)
    ///
    /// - Parameter params: Parameters of request
    @discardableResult
    public func loadData(with params: [String: Any]?) -> ApiDelegate {
        
        if self.isLoading {
            debugPrint("API manager current is requesting, if you want to reload, call cancel() and retry")
            return defaultDelegate
        }
        self.isLoading = true
        self.cancel()
        
        // cache parameters
        self.params = params
        
        self.request = KMRequestGenerator.generateRequest(withApi: self,
                                                          method: self.child!.httpMethod,
                                                          params: params,
                                                          encoding: self.child!.encoding)
        
        if let serializer = self.child?.responseSerializer {
            self.request?.responseData(completionHandler: { (resp) in
                switch resp.result {
                case .success(_):
                    do {
                        let result = try serializer(resp)
                        self.deal(value: result, error: nil)
                    } catch {
                        self.deal(value: nil, error: error as NSError)
                    }
                case .failure(let error):
                    self.deal(value: nil, error: error as NSError)
                }
            })
        } else {
            self.request?.responseJSON(completionHandler: { (resp) in
                
                if let value = resp.result.value {
                    guard let data = value as? [String: Any] else {
                        self.deal(value: nil, error: Errors.responseError)
                        return
                    }
                    self.deal(value: data, error: nil)
                    
                } else {
                    self.deal(value: nil, error: resp.result.error as NSError?)
                }
            })
        }
        return defaultDelegate
    }
    
    /// Deal the response JSON object
    ///
    /// - Parameters:
    ///   - value: Json value
    ///   - error: If there's an error
    private func deal(value: [String: Any]?, error: NSError?) {
        self.isLoading = false
        var err: NSError?
        
        // HTTP request success
        if let value = value {
            self.data = value
            
            // If the server has retry mechanism
            if self.autoProcessServerData,
                let server = self.child!.server as? ServerDataProcessProtocol {
                
                do {
                    try server.handle(data: value)
                    self.loadingComplete()
                    self.successRoute()
                } catch {
                    err = error as NSError
                }
            } else {
                self.loadingComplete()
                self.successRoute()
            }
        }
            // HTTP request error
        else if let error = error {
            err = error as NSError
        }
            // Value is not a Dictionary
        else {
            err = Errors.unknownError
        }
        
        if let err = err {
            // Retry operations
            if self.shouldAutoRetry,
                let maxCount = self.child!.autoRetryMaxCount(withErrorCode: err.code),
                let interval = self.child!.retryTimeInterval(withErrorCode: err.code) {
                
                if self.retryTimes < maxCount {
                    
                    DispatchQueue
                        .global(qos: .default)
                        .asyncAfter(deadline: DispatchTime(uptimeNanoseconds: interval), execute: {
                            self.loadData(with: self.params)
                        })
                    self.retryTimes += 1
                    return
                }
            }
            // reset the retry count
            self.retryTimes = 0
            
            self.loadingFailed(with: err)
            self.failureRoute(with: err)
        }
        SystemLog.write("API response - name: \(self.child?.apiName ?? "")\n data: \(value ?? [:])\n error: \(err.debugDescription)")
    }
    
    /// Cancel current request if exists.
    public func cancel() -> Void {
        self.request?.cancel()
    }
    
    private func successRoute() -> Void {
        self.doOnMainQueue({
            self.delegate?.API(self, finishedWithOriginData: self.data!)
        })
        self.retryTimes = 0
        if self.shouldAutoCacheResultWhenSucceed {
            if self.cacheKey == nil {
                self.cacheKey = "\(self.child!.apiName)_\(API.keyNum)"
                API.keyNum += 1
            }
            NetworkCache.memoryCache.set(object: self.data!, forKey: self.child!.apiName)
        }
    }
    
    private func failureRoute(with error: NSError) -> Void {
        self.doOnMainQueue({
            self.delegate?.API(self, failedWithError: error)
        })
    }
    
    // MARK: - Callbacks
    
    /// A hook of success request
    open func loadingComplete() -> Void {
        // hook
    }
    
    /// A hook of failed request
    ///
    /// - Parameter error: Error that occured
    open func loadingFailed(with error: NSError) -> Void {
        // hook
    }
    
    // MARK: - Others
    
    /// HTTP request is succeed or not
    open func isSuccess() -> Bool {
        return self.data != nil && !self.isLoading
    }
    
    /// Data which received from server and transformed to JSON
    ///
    /// - Returns: origin data
    open func originData() -> [String: Any]? {
        return self.data
    }
    
    /// Get url string including server url, API version and API name
    open var apiURLString: String {
        if self.urlString == nil {
            if self.child!.apiVersion.isEmpty {
                self.urlString = self.child!.server.url + "/" + self.child!.apiName
            } else {
                self.urlString = self.child!.server.url + "/" + self.child!.apiVersion + "/" + self.child!.apiName
            }
        }
        return self.urlString!
    }
    
    /// Get child's HTTP headers
    public var HTTPHeaders: Alamofire.HTTPHeaders? {
        return self.child?.headers()
    }
    
    private func doOnMainQueue(_ block: @escaping () -> ()) -> Void {
        DispatchQueue.main.async(execute: block)
    }
}
