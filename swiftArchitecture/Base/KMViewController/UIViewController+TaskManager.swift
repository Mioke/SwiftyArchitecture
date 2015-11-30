//
//  UIViewController+TaskManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/27.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

extension UIViewController: TaskExecutor {
    
    typealias receivDataType = AnyObject
    
    func doTask(task: () -> receivDataType, identifier: String) {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) { () -> Void in
            
            let result = task()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.finishTaskWithReuslt(result, identifier: identifier)
            })
        }
    }
    
    @available(*, deprecated, message="尽量不要使用block回调，保证结构统一性。To make sure the unitarity of callback ,don't use this except neccesary")
    func doTask(task: () -> receivDataType, callBack: (receivDataType) -> Void) {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) { () -> Void in
            
            let result = task()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.dealErrorResult(result)
                callBack(result)
            })
        }
    }
    /**
     Task's callback. 任务的回调函数
     
     - parameter result:     Task execution's result. 任务执行返回的结果
     - parameter identifier: Task's identifier. 任务的标识
     */
    func finishTaskWithReuslt(result: receivDataType, identifier: String) {
        self.dealErrorResult(result)
    }
    
    private func dealErrorResult(result: receivDataType) -> Bool {
        
        if let _ = (result as? ResultType<receivDataType>)?.error() {
            // do something
            
            return false
        }
        return true
    }
}