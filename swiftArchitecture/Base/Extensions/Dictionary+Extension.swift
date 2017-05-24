//
//  Dictionary+Extension.swift
//  FileMail
//
//  Created by jiangkelan on 24/05/2017.
//  Copyright © 2017 xlvip. All rights reserved.
//

import Foundation

extension Dictionary {
    
    static func +(lhs: Dictionary, rhs: Dictionary) -> Dictionary {
        var rst = lhs
        for pair in rhs {
            rst.updateValue(pair.value, forKey: pair.key)
        }
        return rst
    }
}
