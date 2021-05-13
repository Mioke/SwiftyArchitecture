//
//  ApiCallbackProtocol.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

/// Describe callback of an api.
public protocol ApiCallbackProtocol: NSObjectProtocol {
    
    associatedtype APIType: ApiInfoProtocol
    
    /// Success callback
    ///
    /// - Parameters:
    ///   - apiManager: api manager which finished
    ///   - result: result of response
    func API(_ api: API<APIType>, finishedWithResult result: APIType.ResultType) -> Void
    
    /// If API returns error or undefined exception, will call this method in delegate.
    /// - ATTENTION: **DON'T** try to solve problems here, only do the reflection after error occured
    /// - Parameters:
    ///   - api: API
    ///   - error: The error occured
    func API(_ api: API<APIType>, failedWithError error: NSError) -> Void
}
