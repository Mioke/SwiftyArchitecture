//
//  Array+Extentions.swift
//  swiftArchitecture
//
//  Created by Mioke on 15/12/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation


extension Array where Element: Comparable {
    
    mutating func quickSort(from from: Int, to: Int) -> Void {
        
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
                    head += 1
                } else {
                    let temp = self[head]
                    self[head] = self[tail]
                    self[tail] = temp
                    dir = !dir
                }
            } else {
                if self[tail] >= key {
                    tail -= 1
                } else {
                    let temp = self[tail]
                    self[tail] = self[head]
                    self[head] = temp
                    dir = !dir
                }
            }
        }
        self.quickSort(from: from, to: head - 1)
        self.quickSort(from: head + 1, to: to)
    }
    
    mutating func heapSort() -> Void {
        
        func heapAdjust(parent: Int, size: Int) -> Void {
            
            var _parent = Int(parent);
            let element = self[_parent]
            
            var child = _parent * 2 + 1
            
            while child < size {
                
                if child + 1 < size && self[child] < self[child+1] {
                    child += 1
                }
                if element > self[child] {
                    break
                }
                self[_parent] = self[child]
                _parent = child
                child = _parent * 2 + 1
            }
            self[_parent] = element
        }
        
//        for var i = self.count / 2 - 1; i >= 0; i -= 1 {
//            heapAdjust(i, size: self.count)
//            Log.debugPrintln(self) 
//        }
        
        for i in (self.count / 2 - 1) ... 0 {
            heapAdjust(i, size: self.count)
            Log.debugPrintln(self)
        }
        
        Log.debugPrintln("---------------")
        
//        for var i = self.count - 1; i > 0; i -= 1 {
//            let temp  = self[0]
//            self[0] = self[i]
//            self[i] = temp
//            
//            heapAdjust(0, size: i)
//            
//            Log.debugPrintln(self)
//        }
        
        for i in (self.count - 1) ..< 0 {
            let temp  = self[0]
            self[0] = self[i]
            self[i] = temp
            
            heapAdjust(0, size: i)
            
            Log.debugPrintln(self)
        }
    }
    
    mutating func insertionSort() -> Void {
        
        for i in 1 ..< self.count {
            var j = i - 1
            let temp = self[i]
            while j >= 0 {
                if self[j] > temp {
                    self[j + 1] = self[j]
                    j = j - 1
                } else {
                    break
                }
            }
            self[j + 1] = temp
        }
    }
    
    mutating func shellSort() -> Void {
        
        var increment = self.count / 2
        Log.debugPrintln(self)
        while increment != 0 {
            
            for i in 0 ... increment {
                var loc = i + increment
                
                while loc < self.count {
                    
                    let temp = self[loc]
                    var pointer = loc - increment
                    while pointer >= i {
                        if self[pointer] > temp {
                            self[pointer + increment] = self[pointer]
                            pointer = pointer - increment
                        } else {
                            break
                        }
                    }
                    self[pointer + increment] = temp
                    loc += increment
                }
            }
                
            Log.debugPrintln(self)
            increment = increment / 2
        }
    }
}