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
    
    mutating func heapSort() -> Void {
        
        func heapAdjust(var parent: Int, size: Int) -> Void {
            let element = self[parent]
            
            var child = parent * 2 + 1
            
            while child < size {
                
                if child + 1 < size && self[child] < self[child+1] {
                    child++
                }
                if element > self[child] {
                    break
                }
                self[parent] = self[child]
                parent = child
                child = parent * 2 + 1
            }
            self[parent] = element
        }
        
        for var i = self.count / 2 - 1; i >= 0; i-- {
            heapAdjust(i, size: self.count)
            Log.debugPrintln(self)
        }
        
        Log.debugPrintln("---------------")
        
        for var i = self.count - 1; i > 0; i-- {
            let temp  = self[0]
            self[0] = self[i]
            self[i] = temp
            
            heapAdjust(0, size: i)
            
            Log.debugPrintln(self)
        }
    }
}