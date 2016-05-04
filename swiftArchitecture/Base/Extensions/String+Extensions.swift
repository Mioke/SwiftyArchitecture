//
//  String+Extensions.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/2.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

extension String {
    
    /**
     Be able to use range to get substring, e.x.: "abced"[0...1] = "ab"
     */
    subscript (r: Range<Int>) -> String {
        get {
            let startIndex = self.startIndex.advancedBy(r.startIndex)
            let endIndex = startIndex.advancedBy(r.endIndex - r.startIndex)
            
            return self[startIndex ..< endIndex]
        }
    }
    /// length of String, number of characters -- Swift 2.0
    var length: Int {
        return self.characters.count
    }
    
    /// MD5 of string, need to #import <CommonCrypto/CommonCrypto.h> in bridge file
    var MD5: String {
        let cString = self.cStringUsingEncoding(NSUTF8StringEncoding)
        let length = CUnsignedInt(
            self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        )
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(
            Int(CC_MD5_DIGEST_LENGTH)
        )
        
        CC_MD5(cString!, length, result)
        
        return String(format:
            "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15])
    }
}

