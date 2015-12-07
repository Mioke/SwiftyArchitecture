//
//  publicFunctions.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/30.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

/**
 代码区块区分
 
 - parameter name:    区块功能描述
 - parameter closure: 执行功能
 */
func scope(name: String, closure: () -> ()) -> Void {
    closure()
}

/// Debug模式下打印
class Log {
    
    class func debugPrintln<T>(value: T) -> Void {
        #if DEBUG
            print(value)
        #endif
    }
}

//public let kServer = "http://115.29.175.210:8009/"
//
//func ServerURLString(interface: String) -> String {
//    return kServer + interface
//}
//
//func ServerURLWithComponent(comp: String) -> NSURL? {
//    return NSURL(string: ServerURLString(comp))
//}



