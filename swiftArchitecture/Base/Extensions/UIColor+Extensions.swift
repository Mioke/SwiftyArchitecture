//
//  UIColor+Extensions.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/8.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

extension UIColor {
    
    class func colorFromHexString(_ hex: String) -> UIColor {
        
        let rgbValue: UnsafeMutablePointer<UInt32>? = nil
        let hexString = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hexString)
        
        scanner.scanHexInt32(rgbValue)
        
        return UIColor(
            red:    CGFloat(rgbValue!.pointee & 0xFF0000 >> 16) / 255.0,
            green:  CGFloat(rgbValue!.pointee & 0x00FF00 >> 8) / 255.0,
            blue:   CGFloat(rgbValue!.pointee & 0xFF) / 255.0,
            alpha:  1)
    }
}
