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
     Be able to use range to get substring, e.x.: "abced"[0..<1] = "a"
     */
    public subscript (r: Range<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
            
            let substring = self.prefix(upTo: endIndex).suffix(from: startIndex)
            return String.init(substring)
        }
    }
    /**
    Be able to use range to get substring, e.x.: "abced"[0...1] = "ab"
    */
    public subscript (r: ClosedRange<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
            
            let substring = self.prefix(through: endIndex).suffix(from: startIndex)
            return String.init(substring)
        }
    }
    /// length of String, number of characters -- Swift 2.0
    public var length: Int {
        return self.count
    }
    
    /*
    /// MD5 of string, need to #import <CommonCrypto/CommonCrypto.h> in bridge file
    var MD5: String {
        
        func another() {
            let cString = self.cString(using: String.Encoding.utf8)
            let length = CUnsignedInt(
                self.lengthOfBytes(using: String.Encoding.utf8)
            )
            let result = UnsafeMutablePointer<CUnsignedChar>.allocate(
                capacity: Int(CC_MD5_DIGEST_LENGTH)
            )
            
            CC_MD5(cString!, length, result)
            
            return String(format:
                "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          result[0], result[1], result[2], result[3],
                          result[4], result[5], result[6], result[7],
                          result[8], result[9], result[10], result[11],
                          result[12], result[13], result[14], result[15])
        }
        
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = self.data(using: String.Encoding.utf8) {
            _ = d.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
                CC_MD5(body, CC_LONG(d.count), &digest)
            }
        }
        
        return (0..<length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
 */
}

public extension Swift.Optional where Wrapped == String {
    @inlinable
    var isEmpty: Bool {
        switch self {
        case .none:
            return true
        case .some(let value):
            return value.isEmpty
        }
    }
}


