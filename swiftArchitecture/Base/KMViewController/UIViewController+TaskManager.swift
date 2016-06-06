//
//  UIViewController+TaskManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/27.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

extension UIViewController: sender, receiver {
    
    typealias receiveDataType = AnyObject
    
    func doTask(task: () throws -> receiveDataType, identifier: String) {
        
//        let block =  {
//            do {
//                let result = try task()
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    self.finishTaskWithReuslt(result, identifier: identifier)
//                })
//            } catch let e {
//                if let error = e as? ErrorResultType {
//                    self.taskCancelledWithError(error, identifier: identifier)
//                } else {
//                    Log.debugPrintln("Undefined error")
//                }
//            }
//        }
//        dispatch_async(dispatch_get_global_queue(0, 0), block)
    }
    
//    @available(*, deprecated, message="尽量不要使用block回调，保证结构统一性。To make sure the unitarity of callback ,don't use this except neccesary")
//    func doTask(task: () throws -> receiveDataType, callBack: (receiveDataType) -> Void, failure: (ErrorResultType) -> Void) {
//        
//        dispatch_async(dispatch_get_global_queue(0, 0)) { () -> Void in
//            
//            do {
//                let result = try task()
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    callBack(result)
//                })
//            } catch let e {
//                if let error = e as? ErrorResultType {
//                    failure(error)
//                } else {
//                    Log.debugPrintln("Undefined error")
//                }
//            }
//        }
//    }
    
//    func taskCancelledWithError(error: ErrorResultType, identifier: String) {
//        NetworkManager.dealError(error)
//    }
    
    /**
     Task's callback. 任务的回调函数
     
     - parameter result:     Task execution's result. 任务执行返回的结果
     - parameter identifier: Task's identifier. 任务的标识
     */
    func finishTaskWithReuslt(result: receiveDataType, identifier: String) {
        
    }
}


