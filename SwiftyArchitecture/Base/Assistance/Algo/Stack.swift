//
//  Stack.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2023/4/7.
//

import Foundation

struct Stack<Element>: Sequence {
    private var elements: [Element]
    
    /// The elements will be popped in the order they appear in the stack
    init<S>(_ sequence: S) where S: Sequence, S.Element == Element {
        elements = sequence.reversed()
    }
    
    init() {
        elements = []
    }
    
    mutating func push(_ element: Element) {
        elements.append(element)
    }
    
    mutating func pop() -> Element? {
        return elements.popLast()
    }
    
    __consuming func makeIterator() -> Stack<Element>.Iterator {
        return Iterator(iterator: elements.reversed().makeIterator())
    }
    
    struct Iterator: IteratorProtocol {
        private var iterator: Array<Element>.Iterator
        fileprivate init(iterator: Array<Element>.Iterator) {
            self.iterator = iterator
        }
        
        mutating func next() -> Element? {
            return iterator.next()
        }
    }
}
