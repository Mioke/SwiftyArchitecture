//
//  UIRelevance.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/30.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

/// UI相关
class UI {
    /* 缓存相关属性，减少调用方法的次数 */
    private static let screenHeight: CGFloat = UIScreen.mainScreen().bounds.size.height
    private static let screenWidth: CGFloat = UIScreen.mainScreen().bounds.size.width
    
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
    /**
     Default font of application
     
     - parameter size: Size of the font
     */
    class func defaultFontWithSize(size: CGFloat) -> UIFont {
        return UIFont.systemFontOfSize(size)
    }
}
