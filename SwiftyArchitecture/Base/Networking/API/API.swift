//
//  BaseApiManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import Alamofire

/// API configuration for running requests and logic.
public struct ApiConfiguration {
    
    /// The default configuration for all APIs.
    public static var `default`: ApiConfiguration = {
        let reportQueue: DispatchQueue = .init(
            label: Consts.networkingDomain + ".default-reporting",
            qos: .default,
            attributes: .concurrent)
        let internalQueue: DispatchQueue = .init(label: Consts.networkingDomain + ".internal")
        return .init(reportingQueue: reportQueue, internalQueue: internalQueue)
    }()
    
    /// The queue of callback handler running.
    var reportingQueue: DispatchQueue
    
    /// The queue of request sender running.
    var internalQueue: DispatchQueue
}


/// Concrete class of api manager, subclass from this class to use it and don't use this class directly.
open class API<T: ApiInfoProtocol>: NSObject {
    
    // MARK: Statics
    
    // MARK: Privates
    fileprivate var request: DataRequest?
    
    fileprivate var retryTimes: Int = 0
    
    fileprivate var result: Swift.Result<T.ResultType, NSError>?
    fileprivate var defaultDelegate: ApiDelegate<T>
    
    private var configuration: ApiConfiguration {
        return customizedConfiguration ?? ApiConfiguration.default
    }
    
    // MARK: Publics
    /// Parameters cache.
    public private(set) var params: T.RequestParam?
    
    /// Request is out-going and not receive the response, that means `YES`.
    public var isLoading = false
    
    /// Interval for request timeout
    public var timeoutInterval: TimeInterval = 20
    
    /// If this property is true, it will auto retry when all situations are eligible
    public var shouldAutoRetry: Bool = true
    
    /// Override the APIConfiguration.default if this property is not empty
    public var customizedConfiguration: ApiConfiguration?
    
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
    public func sendRequest(with params: T.RequestParam?) -> ApiDelegate<T> {
        configuration.internalQueue.async {
            guard !self.isLoading else {
                KitLogger.error("API manager current is requesting, if you want to reload, call cancel() and retry")
                return
//                return defaultDelegate
            }
            self.isLoading = true
            // cache parameters
            self.params = params
            do {
                try ApiRouterContainer.shared.router(withType: T.self).route(api: self)
            } catch {
                self.deal(value: nil, error: error as NSError)
            }
        }
        return delegate ?? defaultDelegate
    }
    
    /// Deal the response JSON object
    ///
    /// - Parameters:
    ///   - value: Json value
    ///   - error: If there's an error
    fileprivate func deal(value: T.ResultType?, error: NSError?) {
        self.isLoading = false
        var err: NSError?
        
        // HTTP request success
        if let value = value {
            result = .success(value)
        }
        // HTTP request error
        else if let error = error {
            err = error as NSError
        }
        // Either no value and error
        else {
            err = KitErrors.unknown
        }
        
        if let err = err {
            // Retry operations
            if self.shouldAutoRetry,
               let maxCount = T.autoRetryMaxCount(withErrorCode: err.code),
               let interval = T.retryTimeInterval(withErrorCode: err.code) {
                
                if self.retryTimes < maxCount {
                    configuration.internalQueue.asyncAfter(
                        deadline: .now() + .seconds(Int(interval)),
                        execute: {
                            self.sendRequest(with: self.params)
                        })
                    self.retryTimes += 1
                    return
                }
            }
            // reset the retry count
            self.retryTimes = 0
            self.failureRoute(with: err)
        } else {
            successRoute()
        }
        
        let logMessage = "API response - name: \(T.apiName)\n data: \(String(describing: value))\n error: \(err.debugDescription)"
        KitLogger.log(level: .info, message: logMessage)
    }
    
    /// Cancel current request if exists.
    public func cancel() -> Void {
        self.request?.cancel()
        self.isLoading = false
    }
    
    private func successRoute() -> Void {
        configuration.reportingQueue.async {
            if let result = self.originData() {
                self.delegate?.API(self, finishedWithResult: result)
            }
        }
        self.retryTimes = 0
    }
    
    private func failureRoute(with error: NSError) -> Void {
        configuration.reportingQueue.async {
            self.delegate?.API(self, failedWithError: error)
        }
    }

    // MARK: - Others
    
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
    open var apiURL: URL {
        return T.server.url
            .appendingPathComponent(T.apiVersion)
            .appendingPathComponent(T.apiName)
    }
    
    /// Get child's HTTP headers
    public var HTTPHeaders: Alamofire.HTTPHeaders? {
        return T.headers()
    }
}

// MARK: - API Routers

extension ApiRouter {
    func tryServerResolve<T>(data: Data, using api: API<T>) -> Bool where T : ApiInfoProtocol {
        do {
            if let server = T.server as? ServerDataProcessProtocol {
                try server.handle(data: data)
            }
            return false
        } catch {
            api.deal(value: nil, error: error as NSError)
            return true
        }
    }
}

class BuiltinApiRouter: ApiRouter {
    
    func route<T>(api: API<T>) throws where T : ApiInfoProtocol {
        api.request = try KMRequestGenerator.generateRequest(withApi: api,
                                                             params: api.params)
        let serializer = T.responseSerializer
        api.request?.responseData(completionHandler: { [weak api, weak self] (resp) in
            guard let api = api else { return }
            switch resp.result {
            case .success(let data):
                do {
                    let result = try serializer.serialize(data: resp)
                    api.deal(value: result, error: nil)
                } catch {
                    if let self, tryServerResolve(data: data, using: api) {
                        return
                    }
                    api.deal(value: nil, error: error as NSError)
                }
            case .failure(let error):
                api.deal(value: nil, error: error as NSError)
            }
        })
    }
}

class ApiRouterMocker: ApiRouter {
    
    weak var datasource: APIRouterMokerDataSource?
    
    func route<T>(api: API<T>) throws where T : ApiInfoProtocol {
        guard let datasource = datasource else {
            return
        }
        guard let constructer = datasource.construct(type: T.self) else {
            throw todo_error()
        }
        let result = constructer(api.params)
        api.deal(value: result, error: nil)
    }
}
