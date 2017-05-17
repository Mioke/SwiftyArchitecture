//
//  UIColor+Extensions.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/8.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

extension UIColor {
    
    public class func color(fromHexString hex: String) -> UIColor {
        
        let hexString = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: hexString)
        
        var rgbValue: UInt32 = 0
        scanner.scanHexInt32(&rgbValue)
        
        return UIColor(
            red:    CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green:  CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue:   CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha:  1)
    }
}
