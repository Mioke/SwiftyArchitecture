//
//  Stack.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2023/4/7.
//

import Foundation

public struct Stack<Element>: Sequence {
    private var elements: [Element]
    
    /// The elements will be popped in the order they appear in the stack
    public init<S>(_ sequence: S) where S: Sequence, S.Element == Element {
        elements = sequence.reversed()
    }
    
    public init() {
        elements = []
    }
    
    public mutating func push(_ element: Element) {
        elements.append(element)
    }
    
    public mutating func pop() -> Element? {
        return elements.popLast()
    }
    
    public __consuming func makeIterator() -> Stack<Element>.Iterator {
        return Iterator(iterator: elements.reversed().makeIterator())
    }
    
    public struct Iterator: IteratorProtocol {
        private var iterator: Array<Element>.Iterator
        init(iterator: Array<Element>.Iterator) {
            self.iterator = iterator
        }
        
        public mutating func next() -> Element? {
            return iterator.next()
        }
    }
}
