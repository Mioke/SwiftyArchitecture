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

/// UI相关
class UI {
    /* 缓存相关属性，减少调用方法的次数 */
    static let screenHeight: CGFloat = UIScreen.mainScreen().bounds.size.height
    static let screenWidth: CGFloat = UIScreen.mainScreen().bounds.size.width
    
    class var SCREEN_HEIGHT: CGFloat {
        get {
            return screenHeight
        }
    }
    class var SCREEN_WIDTH: CGFloat {
        get {
            return screenWidth
        }
    }
}