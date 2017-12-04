//
//  ApiDelegate.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 05/09/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import UIKit

public typealias ApiDelegateResponse = (_ api: BaseApiManager, _ data: Any?, _ error: NSError?) -> Void

open class ApiDelegate: NSObject {
    
    fileprivate var response: ApiDelegateResponse?
    
    @discardableResult
    open func response(_ resp: @escaping ApiDelegateResponse) -> ApiDelegate {
        self.response = resp
        return self
    }
}

extension ApiDelegate: ApiCallbackProtocol {
    public func ApiManager(_ apiManager: BaseApiManager, failedWithError error: NSError) {
        self.response?(apiManager, nil, error)
    }
    public func ApiManager(_ apiManager: BaseApiManager, finishWithOriginData data: [String : Any]) {
        self.response?(apiManager, data, nil)
    }
}
