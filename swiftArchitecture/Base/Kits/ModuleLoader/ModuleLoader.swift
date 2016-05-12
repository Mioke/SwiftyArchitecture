//
//  ModuleLoader.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 5/12/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit

class ModuleLoader: NSObject {
    
    enum OperationLevel: Int {
        case High; case Low; case Default
    }
    
    private static var defaultLoader: ModuleLoader? = ModuleLoader()
    
    class func loader() -> ModuleLoader {
        if ModuleLoader.defaultLoader == nil {
            ModuleLoader.defaultLoader = ModuleLoader()
        }
        return ModuleLoader.defaultLoader!
    }
    
    let group: dispatch_group_t = dispatch_group_create()
    
    var maxConcurrentNum: Int = 3
    var currentNum: Int = 0
    
    private var operations: [OperationLevel: [() -> ()]]
    
    override init() {
        operations = [.High: [], .Default: [], .Low: []]
        super.init()

        dispatch_group_notify(group, dispatch_get_main_queue()) {
            self.currentNum = 0
            self.run()
        }
    }
    
    func addOperation(level: ModuleLoader.OperationLevel = .Default, operation: () -> ()) -> Void {
        
        operations[level]! += [operation]
    }
    
    func run() -> Void {
        while currentNum < maxConcurrentNum {
            
            var op: (() -> ())? = nil
            var priority: dispatch_queue_priority_t = DISPATCH_QUEUE_PRIORITY_DEFAULT
            
            if operations[.High]!.count > 0 {
                op = operations[.High]!.removeFirst()
                priority = DISPATCH_QUEUE_PRIORITY_HIGH
                
            } else if operations[.Default]!.count > 0 {
                op = operations[.Default]!.removeFirst()
                priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                
            } else if operations[.Low]!.count > 0 {
                op = operations[.Low]!.removeFirst()
                priority = DISPATCH_QUEUE_PRIORITY_BACKGROUND
            }
            guard op != nil else {
                ModuleLoader.defaultLoader = nil
                return
            }
            self.currentNum += 1
            dispatch_group_async(group, dispatch_get_global_queue(priority, 0), {
                op?()
            })
        }
    }
}

