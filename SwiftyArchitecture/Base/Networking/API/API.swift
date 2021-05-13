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
open class API<T: ApiInfoProtocol>: NSObject {
    
    // MARK: Statics
    
    // MARK: Privates
    fileprivate var request: DataRequest?
    
    fileprivate var retryTimes: Int = 0
    
    fileprivate var result: Swift.Result<T.ResultType, NSError>?
    fileprivate var params: [String: Any]?
    fileprivate var urlString: String?
    fileprivate var defaultDelegate: ApiDelegate<T>
    
    // MARK: Publics
    
    /// Request is out-going and not receive the response, that means `YES`.
    public var isLoading = false
    
    /// Interval for request timeout
    public var timeoutInterval: TimeInterval = 20
    
    /// Whether process the reponse data from server.
    public var autoProcessServerData: Bool = true
    
    /// If this property is true, it will auto retry when all situations are eligible
    public var shouldAutoRetry: Bool = true
    
    // MARK: Initialization
    public override init() {
        defaultDelegate = ApiDelegate<T>()
        super.init()
        delegate = defaultDelegate
    }
    
    
    // MARK: - Actions
    
    /// Callback delegate, for receiving response.
    internal weak var delegate: ApiDelegate<T>?
    
    /// Send request (for GET, POST)
    ///
    /// - Parameter params: Parameters of request
    @discardableResult
    public func loadData(with params: [String: Any]?) -> ApiDelegate<T> {
        
        if self.isLoading {
            debugPrint("API manager current is requesting, if you want to reload, call cancel() and retry")
            return defaultDelegate
        }
        self.isLoading = true
        self.cancel()
        
        // cache parameters
        self.params = params
        
        do {
            self.request = try KMRequestGenerator.generateRequest(withApi: self,
                                                                  params: params)
        } catch {
            defer {
                self.deal(value: nil, error: error as NSError)
            }
            return defaultDelegate
        }
        
        let serializer = T.responseSerializer
        self.request?.responseData(completionHandler: { (resp) in
            switch resp.result {
            case .success(_):
                do {
                    let result = try serializer.serialize(data: resp)
                    self.deal(value: result, error: nil)
                } catch {
                    self.deal(value: nil, error: error as NSError)
                }
            case .failure(let error):
                self.deal(value: nil, error: error as NSError)
            }
        })
        
        return defaultDelegate
    }
    
    /// Deal the response JSON object
    ///
    /// - Parameters:
    ///   - value: Json value
    ///   - error: If there's an error
    private func deal(value: T.ResultType?, error: NSError?) {
        self.isLoading = false
        var err: NSError?
        
        // HTTP request success
        if let value = value {
            self.result = .success(value)
            
            // If the server has retry mechanism
            if self.autoProcessServerData,
                let server = T.server as? ServerDataProcessProtocol {
                
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
                let maxCount = T.autoRetryMaxCount(withErrorCode: err.code),
                let interval = T.retryTimeInterval(withErrorCode: err.code) {
                
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
            
//            self.loadingFailed(with: err)
            self.failureRoute(with: err)
        }
        SystemLog.write("API response - name: \(T.apiName)\n data: \(String(describing: value))\n error: \(err.debugDescription)")
    }
    
    /// Cancel current request if exists.
    public func cancel() -> Void {
        self.request?.cancel()
    }
    
    private func successRoute() -> Void {
        self.doOnMainQueue({
            if let result = self.originData() {
                self.delegate?.API(self, finishedWithResult: result)
            }
        })
        self.retryTimes = 0
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
        switch self.result {
        case .success(_):
            return !self.isLoading
        default:
            return false
        }
    }
    
    /// Data which received from server and transformed to JSON
    ///
    /// - Returns: origin data
    open func originData() -> T.ResultType? {
        if case .success(let data) = self.result {
            return data
        }
        return nil
    }
    
    /// Get url string including server url, API version and API name
    open var apiURLString: String {
        if self.urlString == nil {
            if T.apiVersion.isEmpty {
                self.urlString = T.server.url + "/" + T.apiName
            } else {
                self.urlString = T.server.url + "/" + T.apiVersion + "/" + T.apiName
            }
        }
        return self.urlString ?? ""
    }
    
    /// Get child's HTTP headers
    public var HTTPHeaders: Alamofire.HTTPHeaders? {
        return T.headers()
    }
    
    private func doOnMainQueue(_ block: @escaping () -> ()) -> Void {
        DispatchQueue.main.async(execute: block)
    }
}
