//
//  publicFunctions.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/30.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

/**
 代码区块区分.
 
 - parameter name:    区块功能描述
 - parameter closure: 执行功能
 */
public func scope(_ name: String, closure: () -> ()) -> Void {
    closure()
}

/// Debug模式下打印。
/// Console log on `DEBUG` mode
open class Log {
    
    public class func debugPrintln(_ value: Any) -> Void {
        #if DEBUG
            print(value)
        #endif
    }
}
