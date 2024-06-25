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
    
    var property: AsyncProperty<Int> = .init(initialValue: -1)
    
    override func setUp() async throws {
        
    }
    
    @available(iOS 16.0, *)
    func testAsyncProperty() async throws {
        
        let expect = XCTestExpectation()
        
        print("Start!")
        
        Task.detached {
            print("detached task 1, prepare to update")
            var times = 0
            while times < 10 {
                print("task 1 updated \(times), before: \(self.property.value)")
                self.property.update(times)
                times += 1
                try await Task.sleep(for: .seconds(0.1))
            }
            expect.fulfill()
        }
        
        Task.detached(weakCapturing: self) { me in
            print("detached task 2, prepare to visit")
            print("task 2 visited current value: \(me.property.value)")
            let (stream, _) = me.property.subscribe()
            for await value in stream {
                print("task 2 notified with:", value)
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
    
    var multicaster2: AsyncMulticast<Int> = .init()
    
    @available(iOS 16.0, *)
    func testAsyncMulticast1() async throws {
        
        let expect = XCTestExpectation()
        let (stream, token) = multicaster2.subscribe()
        
        Task {
            var results = [Int]()
            for try await item in stream {
                results.append(item)
            }
            XCTAssert(results.count == 3)
            expect.fulfill()
        }
        
        Task {
            multicaster2.cast(1)
            try await Task.sleep(for: Duration.seconds(2))
            multicaster2.cast(2)
            try await Task.sleep(for: Duration.seconds(2))
            multicaster2.cast(3)
            token.unsubscribe()
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
    
    // Test deinit
    @available(iOS 16.0, *)
    func testAsyncMulticast2() async throws {
        
        let expect = XCTestExpectation()
        let (stream, token) = multicaster2.subscribe()
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
            multicaster2.cast(1)
            try await Task.sleep(for: Duration.seconds(2))
            multicaster2 = .init()
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
    
    // Test buffer
    @available(iOS 16.0, *)
    func testAsyncMulticast3() async throws {
        
        let expect = XCTestExpectation()
        let multicaster = AsyncMulticast<Int>(bufferSize: 2)
        let (stream, token) = multicaster.subscribe()
        token.bindLifetime(to: self)
        
        Task {
            var results = [Int]()
            for try await item in stream {
                results.append(item)
            }
            XCTAssert(results == multicaster.buffer)
            print(multicaster.lastElement() as Any)
            expect.fulfill()
        }
        
        Task {
            multicaster.cast(1)
            multicaster.cast(2)
            try await Task.sleep(for: Duration.seconds(2))
            token.unsubscribe()
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
    
    func testTimeout1() async throws {
        let result = try? await timeoutTask(with: 2 * Consts.nanosecondsPerSecond) {
            var count = 0
            while true {
                count += 1
                if count == 100 {
                    count = 0
                    /// - Important: In this computationally-intensive process, because this process already take
                    /// place in this thread and there is no other place for concurrency system to check this task
                    /// is cancelled or not, so we must explicitly call `checkCancellaction()`, and better to
                    /// `yield()` once for asynchronisely call.
                    try Task.checkCancellation()
//                    await Task.yield()
                }
            }
            XCTAssert(false)
            return "some"
        } onTimeout: {
            print("ext: on timeout")
            XCTAssert(true)
        }
        
        print(result)
    }
    
    @available(iOS 16.0, *)
    func testTimeout2() async throws {
        
        let task = Task<String, any Error> {
            var count = 0
            while true {
                count += 1
                if count == 100 {
                    count = 0
                    /// - Important: In this computationally-intensive process, because this process already take
                    /// place in this thread and there is no other place for concurrency system to check this task
                    /// is cancelled or not, so we must explicitly call `checkCancellaction()`, and better to
                    /// `yield()` once for asynchronisely call.
                    try Task.checkCancellation()
                    await Task.yield()
                }
            }
            XCTAssert(false)
            return "some"
        }
        
        do {
            _ = try await task.value(timeout: .seconds(2)) {
                print("on timeout")
            }
        } catch {
            print("###", error)
            
            if case Task<String, any Error>.CustomError.timeout = error {
                XCTAssert(true)
            } else {
                XCTAssert(false)
            }
        }
    }
    
    @available(iOS 16.0, *)
    func testTimeout3() async throws {
        
        let task = Task<String, any Error> {
            try await Task.sleep(for: .seconds(10))
            print("# done")
            return "some"
        }
        
        Task {
            try await Task.sleep(for: .seconds(2))
            print("# cancelling")
            task.cancel()
        }
        
        do {
            _ = try await task.value(timeout: .seconds(5)) {
                print("on timeout")
            }
            print("# value")
            
        } catch {
            print("###", error, await task.result)

            if /*case Task<String, any Error>.CustomError.timeout = error*/ error is CancellationError {
                XCTAssert(true)
            } else {
                XCTAssert(false)
            }
        }
    }
    
    @available(iOS 16.0, *)
    func testTimeout4() async throws {
        
        let task = Task<String, any Error> {
            while true { }
        }
        
        Task {
            try await Task.sleep(for: .seconds(2))
            print("# cancelling")
            task.cancel()
        }
        
        do {
            _ = try await task.value(timeout: .seconds(5)) {
                print("on timeout")
            }
            print("# value")
            
        } catch {
            print("###", error)
            
            if case Task<String, any Error>.CustomError.timeout = error {
                XCTAssert(true)
            } else {
                XCTAssert(false)
            }
        }
    }
    
    
}

@available(iOS 16, *)
class TaskQueueTestCases: XCTestCase {
    
    func testNormal() async {
        let queue = TaskQueue<Int>()
        var tasks: [Task<Int, Never>] = []
        let assuming = (0..<10).reduce(into: Array<Int>.init()) { $0.append($1) }
            
        for index in assuming {
            let task = queue.enqueueTask(id: "\(index)") {
                try! await Task.sleep(for: .seconds(1))
                print("running", index)
                return index
            }
            tasks.append(task)
        }
        
        try! await Task.sleep(for: .seconds(5))
        print("Start to observe.")
        
        var results : [Int] = []
        for task in tasks {
            results.append(await task.value)
        }
        
        XCTAssert(results == assuming)
        
    }
    
    func testThrowingQueue() async {
        let queue = ThrowingTaskQueue<Int, Swift.Error>()
        let task = queue.enqueueTask(id: "1") {
            return .failure(NSError(domain: "1", code: 1))
        }
        if case .failure = await task.value {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testOrder() async {
        let queue = TaskQueue<Int>()
        
        var counts = 0
        let getCounts: () -> Int = {
            counts += 1
            return counts
        }
        
        async let result1 = queue.task(id: "1") {
            print("run 1")
            return getCounts()
        }
        async let result2 = queue.task(id: "2") {
            print("run 2")
            return getCounts()
        }
        
//        print(await result1, await result2)
        
        let result3 = await queue.task(id: "3") {
            print("run 3")
            return getCounts()
        }
        let result4 = await queue.task(id: "4") {
            print("run 4")
            return getCounts()
        }
        
        print(result3, result4)
        print(await result2, await result1)
        
        // !! REDICULOUS !!
        // run 1 and run 2 are randomly inserted between `run 3` and `run 4`
    }
    
    func testOrder2() async {
        let queue = TaskQueue<Int>()
        
        var counts = 0
        let getCounts: () -> Int = {
            counts += 1
            return counts
        }
        
        var order: [Int] = []
        
        let result1 = await queue.task(id: "1") {
            print("run 1")
            let value = getCounts()
            order.append(value)
            return value
        }
        let result2 = await queue.task(id: "2") {
            print("run 2")
            let value = getCounts()
            order.append(value)
            return value
        }
        
        let result3 = await queue.task(id: "3") {
            print("run 3")
            let value = getCounts()
            order.append(value)
            return value
        }
        let result4 = await queue.task(id: "4") {
            print("run 4")
            let value = getCounts()
            order.append(value)
            return value
        }
        
        print(result1, result2, result3, result4)
        
        XCTAssert(order == [1,2,3,4])
    }
}
