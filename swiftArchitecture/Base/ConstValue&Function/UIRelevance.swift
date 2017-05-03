//
//  UIRelevance.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/30.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

/// UI相关类，可以用extension添加App UI属性
final public class UI {
    /* 缓存相关属性，减少调用方法的次数 */
    fileprivate static let screenHeight: CGFloat = UIScreen.main.bounds.size.height
    fileprivate static let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    
    public class var SCREEN_HEIGHT: CGFloat {
        get {
            return screenHeight
        }
    }
    public class var SCREEN_WIDTH: CGFloat {
        get {
            return screenWidth
        }
    }
    /// For changing the default font.
    public static var _defaultFont: UIFont = UIFont.systemFont(ofSize: 12)
    /**
     Default font of application
     
     - parameter size: Size of the font
     */
    public class func defaultFont(ofSize size: CGFloat) -> UIFont {
        return self._defaultFont.withSize(size)
    }
}
