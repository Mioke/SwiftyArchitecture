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
        return .init(reportingQueue: reportQueue)
    }()
    
    /// The queue of callback handler running.
    var reportingQueue: DispatchQueue
}


/// Concrete class of api manager, subclass from this class to use it and don't use this class directly.
open class API<T: ApiInfoProtocol>: NSObject {
    
    // MARK: State
    public actor State {
        var request: DataRequest?
        var retryTimes: Int = 0
        var lastResult: Swift.Result<T.ResultType, NSError>?
        
        /// Parameters cache.
        public internal(set) var params: T.RequestParam?
        /// Request is out-going and not receive the response, that means `YES`.
        public var isLoading: Bool = false
        /// If this property is true, it will auto retry when all situations are eligible
        public var shouldAutoRetry: Bool = true
        /// Interval for request timeout
        public var timeoutInterval: TimeInterval = 20
    }
    
    public var state: State = .init()
    
    // MARK: Privates
    private var configuration: ApiConfiguration {
        return customizedConfiguration ?? ApiConfiguration.default
    }
    
    // MARK: Publics
    /// Override the APIConfiguration.default if this property is not empty
    public var customizedConfiguration: ApiConfiguration?
    
    // MARK: Initialization
    public override init() {
        super.init()
    }
    
    // MARK: - Actions
    
    /// Send a request (for GET, POST).
    ///
    /// - Parameter params: Parameters of request
    public func sendRequest(with params: T.RequestParam?) async throws -> T.ResultType {
        guard await !state.isLoading else { throw KitErrors.inProgressError }
        
        await state.invoke { state in
            state.isLoading = true
            state.params = params
        }
        
        return try await ApiRouterContainer.shared.router(withType: T.self).route(api: self)
    }
    
    /// Deal the response JSON object
    ///
    /// - Parameters:
    ///   - value: Json value
    ///   - error: If there's an error
    fileprivate func deal(value: T.ResultType?, error: NSError?) async throws -> T.ResultType {
        await state.invoke { $0.isLoading = false }
        var err: NSError?
        
        // HTTP request success
        if let value = value {
            await state.invoke { $0.lastResult = .success(value) }
        }
        // HTTP request error
        else {
            err = error ?? KitErrors.unknown
        }
        
        let logMessage = "API response - name: \(T.apiName)\n data: \(String(describing: value))\n error: \(err.debugDescription)"
        KitLogger.log(level: .info, message: logMessage)
        
        if let err = err {
            // Retry operations
            if await state.shouldAutoRetry,
               let maxCount = T.autoRetryMaxCount(withErrorCode: err.code),
               let interval = T.retryTimeInterval(withErrorCode: err.code),
               await state.retryTimes < maxCount {
                
                let task = Task {
                    try await Task.sleep(nanoseconds: interval * Consts.nanosecondsPerSecond)
                    return try await self.sendRequest(with: state.params)
                }
                await state.invoke { $0.retryTimes += 1 }
                return try await task.value // recursive here, be aware.
            }
            // reset the retry count
            await state.invoke { $0.retryTimes = 0 }
            throw err
        } else {
            return await originData()!
        }
    }
    
    /// Cancel current request if exists.
    public func cancel() async -> Void {
        await state.invoke { state in
            state.request?.cancel()
            state.isLoading = false
        }
    }

    // MARK: - Others
    
    /// Data which received from server and transformed to JSON
    ///
    /// - Returns: origin data
    open func originData() async -> T.ResultType? {
        if case .success(let data) = await state.invoke({ $0.lastResult }) {
            return data
        }
        return nil
    }
    
    /// Get url string including server url, API version and API name
    open var apiURL: URL {
        return T.server.url.appendingPathComponent(T.apiVersion).appendingPathComponent(T.apiName)
    }
    
    /// Get child's HTTP headers
    public var HTTPHeaders: Alamofire.HTTPHeaders? {
        return T.headers()
    }
}

// MARK: - API Routers

extension ApiRouter {
    func tryServerResolve<T>(data: Data, using api: API<T>) -> NSError? where T : ApiInfoProtocol {
        do {
            if let server = T.server as? ServerDataProcessProtocol {
                try server.handle(data: data)
            }
        } catch {
            return error as NSError
        }
        return nil
    }
}

class BuiltinApiRouter: ApiRouter {
    
    func route<T>(api: API<T>) async throws -> T.ResultType where T : ApiInfoProtocol {
        return try await api.state.invoke { [weak self] state in
            let request = try await KMRequestGenerator.generateRequest(withApi: api,
                                                                       params: state.params)
            state.request = request
            let serializer = T.responseSerializer
            let resp = await request.serializingData().response
            
            var finalError = resp.error?.wrap()
            
            if let data = resp.data {
                do {
                    let result = try serializer.serialize(data: resp)
                    return try await api.deal(value: result, error: nil)
                } catch {
                    if let self, let serverHandledError = tryServerResolve(data: data, using: api) {
                        finalError = serverHandledError
                    }
                    finalError = error as NSError
                }
            }
            return try await api.deal(value: nil, error: finalError)
        }
    }
}

class ApiRouterMocker: ApiRouter {
    
    weak var datasource: APIRouterMokerDataSource?
    
    func route<T>(api: API<T>) async throws -> T.ResultType where T : ApiInfoProtocol {
        guard let datasource = datasource else {
            throw todo_error()
        }
        guard let constructer = datasource.construct(type: T.self) else {
            throw todo_error()
        }
        
        var maybeError: NSError?
        var result: T.ResultType?
        do { result = try constructer(await api.state.params) }
        catch { maybeError = error as NSError}
        return try await api.deal(value: result, error: maybeError)
    }
}

extension AFError {
    func wrap() -> NSError {
        return NSError(domain: Consts.defaultDomain,
                       code: 776,
                       userInfo: [NSLocalizedDescriptionKey: localizedDescription,
                                  NSLocalizedFailureErrorKey: errorDescription ?? "None"])
    }
}
