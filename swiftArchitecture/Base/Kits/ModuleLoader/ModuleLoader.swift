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
    
    fileprivate static var defaultLoader: ModuleLoader? = ModuleLoader()
    
    class func loader() -> ModuleLoader {
        if ModuleLoader.defaultLoader == nil {
            ModuleLoader.defaultLoader = ModuleLoader()
        }
        return ModuleLoader.defaultLoader!
    }
    
    let group: DispatchGroup = DispatchGroup()
    
    var maxConcurrentNum: Int = 3
    var currentNum: Int = 0
    
    fileprivate var operations: [ModuleLoader.OperationLevel: [() -> ()]]
    
    override init() {
        operations = [.high: [], .default: [], .low: []]
        super.init()

        group.notify(queue: DispatchQueue.main) {
            self.currentNum = 0
            self.run()
        }
    }
    
    func add(_ level: ModuleLoader.OperationLevel = .default, operation: @escaping () -> ()) -> Void {
        operations[level]! += [operation]
    }
    
    func run() -> Void {
        
        while currentNum < maxConcurrentNum {
            
            var op: (() -> ())? = nil
            var priority: DispatchQoS = DispatchQoS.default
            
            if operations[.high]!.count > 0 {
                op = operations[.high]!.removeFirst()
                priority = .utility
                
            } else if operations[.default]!.count > 0 {
                op = operations[.default]!.removeFirst()
                priority = .default
                
            } else if operations[.low]!.count > 0 {
                op = operations[.low]!.removeFirst()
                priority = .background
            }
            guard op != nil else {
                ModuleLoader.defaultLoader = nil
                return
            }
            self.currentNum += 1
            
            DispatchQueue.global(qos: priority.qosClass).async {
                op?()
            }
        }
    }
}

