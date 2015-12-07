//
//  ApiCallbackProtocol.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

protocol ApiCallbackProtocol: NSObjectProtocol {

    func ApiManager(apiManager: BaseApiManager, finishWithOriginData data: AnyObject) -> Void
    
    func ApiManager(apimanager: BaseApiManager, failedWithError: ErrorResultType) -> Void
}
