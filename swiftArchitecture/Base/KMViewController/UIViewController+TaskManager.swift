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
    
    func doTask(task: () -> receivDataType, callBack: (receivDataType) -> Void) {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) { () -> Void in
            
            let result = task()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callBack(result)
            })
        }
    }
    
    func finishTaskWithReuslt(result: receivDataType, identifier: String) {
        
        if let _ = (result as? ResultType<receivDataType>)?.error() {
            // do something
        }
    }
}