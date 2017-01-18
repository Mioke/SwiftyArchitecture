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
        case high; case low; case `default`
    }
    
    fileprivate static var defaultLoader: ModuleLoader?
    
    class func loader() -> ModuleLoader {
        if ModuleLoader.defaultLoader == nil {
            ModuleLoader.defaultLoader = ModuleLoader()
        }
        return ModuleLoader.defaultLoader!
    }
    
    private let queue = DispatchQueue(label: "com.klein.moduleloader")
    private let group: DispatchGroup = DispatchGroup()
    
    private var maxConcurrentNum: Int = 3
    private var currentNum: Int = 0
    
    fileprivate var operations: [ModuleLoader.OperationLevel: [() -> ()]]
    
    private override init() {
        operations = [.high: [], .default: [], .low: []]
        super.init()

        group.notify(queue: DispatchQueue.main) {
            self.currentNum = 0
            self.run()
        }
    }
    
    func add(level: ModuleLoader.OperationLevel = .default, operation: @escaping () -> ()) -> Void {
        operations[level]! += [operation]
    }
    
    func run() -> Void {
        
        self.queue.async {
            
            while (self.operations[.high]!.count > 0
                || self.operations[.`default`]!.count > 0
                || self.operations[.low]!.count > 0) {
                
                if self.currentNum < self.maxConcurrentNum {
                    
                    var op: (() -> ())? = nil
                    var priority: DispatchQoS = DispatchQoS.default
                    
                    if self.operations[.high]!.count > 0 {
                        op = self.operations[.high]!.removeFirst()
                        priority = .utility
                        
                    } else if self.operations[.default]!.count > 0 {
                        op = self.operations[.default]!.removeFirst()
                        priority = .default
                        
                    } else if self.operations[.low]!.count > 0 {
                        op = self.operations[.low]!.removeFirst()
                        priority = .background
                    }
                    guard op != nil else {
                        ModuleLoader.defaultLoader = nil
                        return
                    }
                    self.currentNum += 1
                    
                    DispatchQueue.global(qos: priority.qosClass).async {
                        op?()
                        self.currentNum -= 1
                    }
                } else {
                    usleep(1000)
                }
            }
        }
    }
}

