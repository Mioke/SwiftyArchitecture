//
//  UIColor+Extensions.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/8.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

extension UIColor {
    
    class func colorFromHexString(hex: String) -> UIColor {
        
        let rgbValue: UnsafeMutablePointer<UInt32> = nil
        let hexString = hex.stringByReplacingOccurrencesOfString("#", withString: "")
        let scanner = NSScanner(string: hexString)
        
        scanner.scanHexInt(rgbValue)
        
        return UIColor(
            red:    CGFloat(rgbValue.memory & 0xFF0000 >> 16) / 255.0,
            green:  CGFloat(rgbValue.memory & 0x00FF00 >> 8) / 255.0,
            blue:   CGFloat(rgbValue.memory & 0xFF) / 255.0,
            alpha:  1)
    }
}