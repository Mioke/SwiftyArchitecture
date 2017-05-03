//
//  ApiCallbackProtocol.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

public protocol ApiCallbackProtocol: NSObjectProtocol {

    func ApiManager(_ apiManager: BaseApiManager, finishWithOriginData data: Any) -> Void
    
    /**
     If API returns error or undefined exception, will call this method in delegate. 
     
     - ATTENTION: **DON'T** try to solve problems here, only do the reflection after error occured
     
     - parameter apimanager:      API manager
     - parameter failedWithError: The error occured
     */
    func ApiManager(_ apiManager: BaseApiManager, failedWithError error: NSError) -> Void
}
