//
//  ConcurrencySupportTests.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/1/16.
//

import Foundation
@testable import MIOSwiftyArchitecture
import XCTest

class ConcurrencySupportTestCases: XCTestCase {
    
    var property: AsyncProperty<Int> = .init(wrappedValue: 1)
    
    override func setUp() async throws {
        
    }
    
    @available(iOS 16.0, *)
    func testAsyncProperty() async throws {
        
        let expect = XCTestExpectation()
        
        print("Start!")
        
        Task.detached {
            print("detached task 1, prepare to update")
            await self.property.update { old in
                try await Task.sleep(for: Duration.seconds(5))
                return 2
            }
            print("detached task 1, updated")
        }
        
        Task.detached(weakCapturing: self) { me in
            print("detached task 2, prepare to visit")
            while true {
                if me.property.state == .ready {
                    let value = try await me.property.value
                    print("detached task 2, visited \(value)")
                    XCTAssert(value == 2)
                    expect.fulfill()
                    return
                } else {
                    print("detached task 2, the property is updating.")
                }
                try await Task.sleep(for: .seconds(0.5))
            }
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
    
    var stream: AsyncThrowingSignalStream<Int> = .init()
    
    @available(iOS 16.0, *)
    func testAsyncThrowingSignalStream1() async throws {
        
        let expect = XCTestExpectation()
        
        Task.detached {
            try await Task.sleep(for: Duration.seconds(2))
            self.stream.send(signal: 1)
            
            try await Task.sleep(for: Duration.seconds(2))
            self.stream.send(signal: 2)
        }
        
        Task {
            let one = try await self.stream.wait { $0 == 1 }
            print("get one")
            XCTAssert(one == 1)
            let two = try await self.stream.wait { $0 == 2 }
            print("get two")
            XCTAssert(two == 2)
            
            expect.fulfill()
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
    
    enum InternalError: Error {
        case testError
    }
    
    // test send error
    @available(iOS 16.0, *)
    func testAsyncThrowingSignalStream2() async throws {
        Task.detached {
            try await Task.sleep(for: Duration.seconds(2))
            self.stream.send(signal: 1)
            
            try await Task.sleep(for: Duration.seconds(2))
            self.stream.send(error: InternalError.testError)
        }
        
        let task = Task {
            let one = try await self.stream.wait { $0 == 1 }
            print("get one")
            XCTAssert(one == 1)
            
            _ = try await self.stream.wait { $0 == 2 }
            print("won't run the following code")
            XCTAssert(false)
        }
        
        switch await task.result {
        case .failure(let error):
            guard let error = error as? InternalError else { XCTAssert(false); return }
            XCTAssert(error == InternalError.testError)
        default:
            break
        }
    }
    
    // Test deinit.
    @available(iOS 16.0, *)
    func testAsyncThrowingSignalStream3() async throws {
        
        let task = Task {
            _ = try await self.stream.wait { $0 == 1 }
            XCTAssert(false)
        }
        
        try await Task.sleep(for: Duration.seconds(2))
        self.stream.invalid()
        self.stream = .init()
        
        switch await task.result {
        case .failure(let error):
            guard let error = error as? AsyncThrowingSignalStream<Int>.SignalError else { XCTAssert(false); return }
            XCTAssert(error == .haventWaitedForValue)
        default:
            break
        }
    }
    
    
    var multicaster: AsyncThrowingMulticast<Int> = .init()
    
    @available(iOS 16.0, *)
    func testAsyncThrowingMulticast1() async throws {
        
        let expect = XCTestExpectation()
        let (stream, token) = multicaster.subscribe()
        
        Task {
            var results = [Int]()
            for try await item in stream {
                results.append(item)
            }
            XCTAssert(results.count == 3)
            expect.fulfill()
        }
        
        Task {
            multicaster.cast(1)
            try await Task.sleep(for: Duration.seconds(2))
            multicaster.cast(2)
            try await Task.sleep(for: Duration.seconds(2))
            multicaster.cast(3)
            token.unsubscribe()
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
    
    // Test deinit
    @available(iOS 16.0, *)
    func testAsyncThrowingMulticast2() async throws {
        
        let expect = XCTestExpectation()
        let (stream, token) = multicaster.subscribe()
        token.bindLifetime(to: self)
        
        Task {
            var results = [Int]()
            for try await item in stream {
                results.append(item)
            }
            XCTAssert(results.count == 1)
            expect.fulfill()
        }
        
        Task {
            multicaster.cast(1)
            try await Task.sleep(for: Duration.seconds(2))
            multicaster = .init()
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
    
    @available(iOS 16.0, *)
    func testAsyncThrowingMulticast3() async throws {
        
        let (stream1, token1) = multicaster.subscribe()
        let (stream2, _) = multicaster.subscribe()
        token1.bindLifetime(to: self)
        // token2 is not used, so the observer will not run.
        
        let task = Task {
            var results = [Int]()
            for try await item in stream1 {
                results.append(item)
            }
            XCTAssert(false)
        }
        
        Task {
            for try await _ in stream2 {
                XCTAssert(false)
            }
        }
        
        Task {
            multicaster.cast(1)
            try await Task.sleep(for: Duration.seconds(2))
            multicaster.cast(error: InternalError.testError)
        }
        
        switch await task.result {
        case .failure(let error):
            guard let error = error as? InternalError else { XCTAssert(false); return }
            XCTAssert(error == InternalError.testError)
        case .success():
            XCTAssert(false)
        }
    }
}
