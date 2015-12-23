//
//  Array+Extentions.swift
//  swiftArchitecture
//
//  Created by Mioke on 15/12/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation


extension Array where Element: Comparable {
    
    mutating func quickSort(from: Int, to: Int) -> Void {
        
        if from >= to {
            return
        }
        let key = self[from]
        
        var head = from
        var tail = to
        
        var dir = false
        
        while head < tail {
            if dir {
                if self[head] <= key {
                    head++
                } else {
                    let temp = self[head]
                    self[head] = self[tail]
                    self[tail] = temp
                    dir = !dir
                }
            } else {
                if self[tail] >= key {
                    tail--
                } else {
                    let temp = self[tail]
                    self[tail] = self[head]
                    self[head] = temp
                    dir = !dir
                }
            }
        }
        self.quickSort(from, to: head - 1)
        self.quickSort(head + 1, to: to)
    }
}