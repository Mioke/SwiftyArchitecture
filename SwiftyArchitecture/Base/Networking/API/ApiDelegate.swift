//
//  ApiDelegate.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 05/09/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit

public typealias ApiDelegateResponse<T: ApiInfoProtocol> = (_ api: API<T>, _ data: T.ResultType?, _ error: NSError?) -> Void

open class ApiDelegate<T: ApiInfoProtocol>: NSObject {
    
    fileprivate var response: ApiDelegateResponse<T>?
    
    open func response(_ resp: @escaping ApiDelegateResponse<T>) -> Void {
        self.response = resp
    }
}

extension ApiDelegate: ApiCallbackProtocol {
    
    public typealias APIType = T
    
    public func API(_ api: API<T>, finishedWithResult result: T.ResultType) {
        self.response?(api, result, nil)
    }
    
    public func API(_ api: API<T>, failedWithError error: NSError) {
        self.response?(api, nil, error)
    }
    
}
