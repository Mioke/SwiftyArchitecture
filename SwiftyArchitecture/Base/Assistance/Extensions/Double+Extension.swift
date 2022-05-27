//
//  Double+Extension.swift
//  FileMail
//
//  Created by jiangkelan on 22/05/2017.
//  Copyright © 2017 xlvip. All rights reserved.
//

import Foundation

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /*
    // Formate to file size string with KB, MB, GB
    func fileSizeFormate() -> String {
        var totalBytes = self / 1024.0
        var multiplyFactor = 0
        let tokens = ["KB","MB","GB","TB"]
        while totalBytes > 1024 {
            totalBytes /= 1024.0
            multiplyFactor += 1
        }
        return "\(String(format:"%.2f",totalBytes))\(tokens[multiplyFactor])"
    }
     */
}
 
