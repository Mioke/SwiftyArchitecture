//
//  ModuleManager+Testable.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/5/23.
//

import Foundation
@testable import MIOSwiftyArchitecture
import XCTest

class InitiatorTestCase: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDemo() {
        let graph: DirectedGraph<Int> = .init()
        
        let a = DirectedGraphNode<Int>(value: 1)
        let b = DirectedGraphNode<Int>(value: 2)
        let c = DirectedGraphNode<Int>(value: 3)
        let d = DirectedGraphNode<Int>(value: 4)
        
        a.out = [b]
        b.out = [c, d]
        c.out = [a]
        
        a.in = [c]
        b.in = [a]
        c.in = [b]
        d.in = [b]
        
        graph.nodes = [a, b, c, d]
        
        XCTAssertTrue(graph.checkCircle())
    }
    
    func testNoCircle() {
        let graph: DirectedGraph<Int> = .init()
        
        let a = DirectedGraphNode<Int>(value: 1)
        let b = DirectedGraphNode<Int>(value: 2)
        let c = DirectedGraphNode<Int>(value: 3)
        let d = DirectedGraphNode<Int>(value: 4)
        
        a.out = [b]
        b.out = [c, d]
        c.out = [d]
        
        
        b.in = [a]
        c.in = [b]
        d.in = [b, c]
        
        graph.nodes = [a, b, c, d]
        
        XCTAssertFalse(graph.checkCircle())
    }
    
    func testVisit() {
        let graph: DirectedGraph<Int> = .init()
        
        let a = DirectedGraphNode<Int>(value: 1)
        let b = DirectedGraphNode<Int>(value: 2)
        let c = DirectedGraphNode<Int>(value: 3)
        let d = DirectedGraphNode<Int>(value: 4)
        
        a.out = [b]
        b.out = [c, d]
        c.out = [d]
        
        
        b.in = [a]
        c.in = [b]
        d.in = [b, c]
        
        graph.nodes = [a, b, c, d]
        
        var route: [Int] = []
        graph.dfsForEach { node in
            route.append(node.value)
        }
        print(route)
        XCTAssert(route.last == 1)
    }
    
    func testBuildTaskGraph() {
        let tasks: [Initiator.Task] = [
            .init(id: "1", dependencies: ["2", "3"], operation: {}),
            .init(id: "2", dependencies: ["4"], operation: {}),
            .init(id: "3", dependencies: ["4"], operation: {}),
            .init(id: "4", dependencies: [], operation: {}),
        ]
        
        let graph = TaskGraphBuilder.buildGraph(with: tasks)
        XCTAssertFalse(graph.checkCircle())
        
        var path: [String] = []
        graph.dfsForEach { node in
            path.append(node.value.identifier)
        }
        print(path)
        
        XCTAssert(path.count == 4)
        XCTAssert(path.first == "4" && path.last == "1")
    }
}
