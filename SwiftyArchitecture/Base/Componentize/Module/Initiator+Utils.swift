//
//  Initiator+LinkedList.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/3/11.
//

import Foundation
import SwiftUI

final class Node<Element> {
    var value: Element
    var pre: Node?
    var next: Node?
    
    init(value: Element) {
        self.value = value
    }
}

class LinkedList<T> {
    var head: Node<T>?
    var tail: Node<T>?
    
    func add(_ node: Node<T>) {
        guard head != nil else {
            // Empty
            head = node
            tail = node
            return
        }
        
        tail?.next = node
        node.pre = tail
        tail = node
    }
    
    func insert(_ newNode: Node<T>, after node: Node<T>) {
        newNode.next = node.next
        node.next = newNode
        newNode.pre = node
        if node === tail {
            tail = newNode
        }
    }
    
    func removeLast() -> Node<T>? {
        let removed = tail
        tail = tail?.pre
        tail?.next = nil
        return removed
    }
    
    func removeAll() {
        head = nil
        tail = nil
    }
    
    func forEach(_ each: (Node<T>) -> Void) {
        var cur = head
        while let temp = cur {
            each(temp)
            cur = temp.next
        }
    }
    
    func map<U>(_ transform: (T) -> U) -> [U] {
        var result: [U] = []
        forEach { node in
            result.append(transform(node.value))
        }
        return result
    }
}

extension LinkedList where T: Equatable {
    func contains(_ element: T) -> Bool {
        var cur = head
        while let value = cur?.value {
            if value == element {
                return true
            } else {
                cur = cur?.next
            }
        }
        return false
    }
}

// MARK: - Directed Graph

class DirectedGraphNode<T: Hashable>: CustomDebugStringConvertible {
    var value: T
    var `in`: Set<DirectedGraphNode<T>> = []
    var out: Set<DirectedGraphNode<T>> = []
    
    var inDegree: Int { return self.in.count }
    var outDegree: Int { return self.out.count }
    
    init(value: T) {
        self.value = value
    }
    
    var debugDescription: String {
        return "<\(value)>"
    }
}

extension DirectedGraphNode: Hashable {
    static func == (lhs: DirectedGraphNode<T>, rhs: DirectedGraphNode<T>) -> Bool {
        return lhs.value == rhs.value
    }
    
    func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
    }
}

class DirectedGraph<T: Hashable> {
    var nodes: Set<DirectedGraphNode<T>> = []
    
    convenience init(nodes: Set<DirectedGraphNode<T>>) {
        self.init()
        self.nodes = nodes
    }
    
    func checkCircle() -> Bool {
        var visited: Set<DirectedGraphNode<T>> = []
        var stack: [DirectedGraphNode<T>] = []
        
        while let first = nodes.filter({ !visited.contains($0) }).first {
            do {
                try visit(first, visited: &visited, stack: &stack)
            } catch {
                return true
            }
        }
        return false
    }
    
    func dfsForEach(_ each: @escaping (DirectedGraphNode<T>) -> Void) -> Void {
        var visited: Set<DirectedGraphNode<T>> = []
        var stack: [DirectedGraphNode<T>] = []
        while let first = nodes.filter({ !visited.contains($0) }).first {
            try? visit(first, visited: &visited, stack: &stack, handler: each)
        }
    }
    
    func dfsMap<U>(_ transform: @escaping (DirectedGraphNode<T>) -> U) -> [U] {
        var visited: Set<DirectedGraphNode<T>> = []
        var stack: [DirectedGraphNode<T>] = []
        var result: [U] = []
        while let first = nodes.filter({ !visited.contains($0) }).first {
            try? visit(first, visited: &visited, stack: &stack, handler: { node in
                result.append(transform(node))
            })
        }
        return result
    }
    
    private func visit(
        _ node: DirectedGraphNode<T>,
        visited: inout Set<DirectedGraphNode<T>>,
        stack: inout [DirectedGraphNode<T>],
        handler: ((DirectedGraphNode<T>) -> Void)? = nil) throws {
            
            if stack.contains(node) {
                throw KitErrors.graphCycle
            }
            
            guard !visited.contains(node) else { return }
            
            visited.update(with: node)
            if node.out.count > 0 {
                stack.append(node); defer { stack.removeLast() }
                try node.out.forEach { out in
                    try visit(out, visited: &visited, stack: &stack, handler: handler)
                }
            }
            handler?(node)
        }
}


// MARK: - Priority Queue
protocol PriorityQueueItem: Identifiable {
    var afterItems: [ID]? { get }
}

/// Light-weight mechanism for enqueue items with priority, but can't check dependency cycle.
class PriorityQueue<T: PriorityQueueItem> {
    var items: [T] = []
    private var initialItems: [T]
    
    init(items: [T]) {
        self.initialItems = items
        while self.initialItems.count > 0 {
            let first = (0, self.initialItems[0])
            enqueue(item: first)
        }
    }
    
    func enqueue(item: (index: Int, value: T)) {
        if let dependencies = item.value.afterItems, dependencies.count > 0 {
            dependencies.compactMap { id -> (index: Int, value: T)? in
                let rst = self.find(id: id, in: self.initialItems)
                if rst == nil {
                    print("[Initiator] Can't find dependency named \(id) which \(item.value.id) needed.")
                }
                return rst
            }.forEach { value in
                enqueue(item: value)
            }
        }
        self.items.append(item.value)
        self.initialItems.remove(at: item.index)
    }
    
    func find(id: T.ID, in array: [T]) -> (index: Int, value: T)? {
        guard let index = array.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return (index, array[index])
    }
}

extension Initiator.Task: PriorityQueueItem {
    typealias ID = String
    var id: ID {
        return self.identifier
    }
    var afterItems: [String]? {
        return self.dependencies
    }
}
