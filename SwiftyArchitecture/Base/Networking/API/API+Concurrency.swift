//
//  API+Concurrency.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/1/3.
//

import Foundation
#if canImport(_Concurrency)

import _Concurrency

public extension API {
    
    /// [Concurrency API] Send a request of GET or POST methods.
    /// - Parameter params: The request's parameters.
    /// - Returns: The request's success result model.
    func request(with params: T.RequestParam?) async throws -> T.ResultType {
        return try await withCheckedThrowingContinuation { continuation in
            sendRequest(with: params).response { api, data, error in
                if let error { continuation.resume(throwing: error) }
                if let data { continuation.resume(returning: data) }
            }
        }
    }
    
}


#endif
