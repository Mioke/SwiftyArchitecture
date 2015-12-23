//
//  CollectionType+Extension.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/4.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

extension CollectionType where Generator.Element: Comparable {
    
    var isSorted: Bool {
        
        if self.count < 3 { return true }
        
        var compare: Int?
        
        for i in self.startIndex..<self.endIndex {
            if compare == nil {
                if self[i] > self[i.successor()] { compare = 0 }
                else { compare = 1 }
                continue
            }
            if compare! == 1 {
                if self[i] > self[i.successor()] { return false }
            } else {
                if self[i] < self[i.successor()] { return false }
            }
        }
        return true
    }
    
}

