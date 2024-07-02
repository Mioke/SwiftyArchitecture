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
        let expect = XCTestExpectation()
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
            try await Task.sleep(for: .seconds(2))
            multicaster.cast(error: InternalError.testError)
            multicaster.cast(2)
            try await Task.sleep(for: .seconds(2))
            expect.fulfill()
        }
        
        switch await task.result {
        case .failure(let error):
            guard let error = error as? InternalError else { XCTAssert(false); return }
            XCTAssert(error == InternalError.testError)
        case .success():
            XCTAssert(false)
        }
        
        await fulfillment(of: [expect])
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
                    await Task.yield()
                }
            }
            XCTAssert(false)
            return "some"
        } onTimeout: {
            print("ext: on timeout")
            XCTAssert(true)
        }
        
        XCTAssert(result == nil)
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
    
    func testNormal() async throws {
        let queue = TaskQueue<Int>()
        var tasks: [Task<Int, Error>] = []
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
            results.append(try await task.value)
        }
        
        XCTAssert(results == assuming)
    }
    
    func testThrowingQueue() async throws {
        let queue = ThrowingTaskQueue<Int, Swift.Error>()
        let task = queue.enqueueTask(id: "1") {
            return .failure(NSError(domain: "1", code: 1))
        }
        if case .failure = try await task.value {
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
    
    var queue : TaskQueue<Int>? = .init()
    
    func testDeallocation1() async {
        let expect = XCTestExpectation()
        Task {
            let result = await self.queue?.task(id: "1") {
                do {
                    try await Task.sleep(for: .seconds(5))
                } catch {
                    print("error", error)
                }
                print(self.queue == nil)
                return 1
            }
            print(result)
            expect.fulfill()
        }
        
        Task {
            try await Task.sleep(for: .seconds(1))
            self.queue = nil
            print("set to nil")
        }
        await fulfillment(of: [expect], timeout: 10)
    }
    
    func testDeallocation2() async throws {
        let expect = XCTestExpectation()
        
        let op: () async -> Int = {
            do {
                print("\(Date()) start")
                try await Task.sleep(for: .seconds(5))
                print("\(Date()) end")
            } catch {
                print("error", error)
            }
            print(self.queue == nil)
            return 1
        }
        
        if let task = self.queue?.enqueueTask(id: "1", task: op) {
            
            Task {
                try await Task.sleep(for: .seconds(1))
                self.queue = nil
                print("set to nil")
            }
            do {
                print(try await task.value)
            } catch {
                XCTAssert(error is CancellationError)
                expect.fulfill()
            }
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
    
    func testDeallocation3() async throws {
        let expect = XCTestExpectation()
        
        let op1: () async -> Int = {
            do { try await Task.sleep(for: .seconds(99)) }
            catch { print("#1 error", error) }
            print(self.queue == nil)
            return 1
        }
        let op2: () async -> Int = {
            do { try await Task.sleep(for: .seconds(3)) }
            catch { print("#2 error", error) }
            print(self.queue == nil)
            return 2
        }
        
        if let task1 = self.queue?.enqueueTask(id: "1", task: op1),
           let task2 = self.queue?.enqueueTask(id: "2", task: op2) {
            
            Task {
                try await Task.sleep(for: .seconds(1))
                weak var tempQueue = self.queue
                self.queue = nil
                print("set to nil", tempQueue)
            }
            Task {
                do {
                    print(try await task2.value)
                    XCTAssert(false)
                } catch {
                    print("waited an error: \(error)")
                    expect.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
    
    func testDeallocation4() async throws {
        let expect = XCTestExpectation()
        
        if let queue = self.queue {
            queue.addTask(id: "1") {
                try! await Task.sleep(for: .seconds(5))
                return 1
            } onFinished: { result in
                XCTAssert(result == nil)
            }
            
            queue.addTask(id: "2") {
                try! await Task.sleep(for: .seconds(3))
                return 2
            } onFinished: { result in
                XCTAssert(result == nil)
                expect.fulfill()
            }
            
            Task {
                try await Task.sleep(for: .seconds(1))
                print("set to nil")
                self.queue = nil
            }
        }
        
        await fulfillment(of: [expect], timeout: 10)
    }
}

@available(iOS 16, *)
class AsyncOperationTestCases: XCTestCase {
    
    func testOperation() async throws {
        let operation: AsyncOperation<Int> = .init {
            try await Task.sleep(for: .seconds(1))
            return 1
        }
        
        let result = try await operation.start()
        XCTAssert(result == 1)
    }
    
    func testOperationMultipleEntry() async throws {
        let operation: AsyncOperation<Int> = .init {
            try await Task.sleep(for: .seconds(1))
            return 1
        }
        
        Task {
            let result = try await operation.start()
            XCTAssert(result == 1)
        }
        
        await Task.yield()
        
        let failedTask = Task {
            return try await operation.start()
        }
        
        if case .failure(let error) = await failedTask.result {
            print(error)
            XCTAssert(error is AsyncOperation<Int>.Error)
        }
    }
    
    func testFlatMap() async throws {
        let operation1: AsyncOperation<Int> = .init {
            print("Enter 1")
            try await Task.sleep(for: .seconds(1))
            print("Ending 1")
            return 1
        }
        
        
        let operation2 = operation1.flatMap { result in
            return .init {
                print("Enter 2")
                try await Task.sleep(for: .seconds(1))
                print("Ending 2")
                return result + 1
            }
        }
        
        let result = try await operation2.start()
        
        XCTAssert(result == 2)
    }
    
    func testMap() async throws {
        let operation1: AsyncOperation<Int> = .init {
            print("Enter 1")
            try await Task.sleep(for: .seconds(1))
            print("Ending 1")
            return 1
        }
        
        
        let operation2 = operation1
            .flatMap { result in
                return .init {
                    print("Enter 2")
                    try await Task.sleep(for: .seconds(1))
                    print("Ending 2")
                    return result + 1
                }
            }
            .map { value in
                value + 1
            }
        
        let result = try await operation2.start()
        
        XCTAssert(result == 3)
    }
    
    func testCombine() async throws {
        let operation1: AsyncOperation<Int> = .init {
            print("Enter 1")
            try await Task.sleep(for: .seconds(1))
            print("Ending 1")
            return 1
        }
        
        let operation2: AsyncOperation<Int> = .init {
            print("Enter 2")
            try await Task.sleep(for: .seconds(1))
            print("Ending 2")
            return 2
        }
        let combined = operation1.combine(operation2)
        let result = try await combined.start()
        
        XCTAssert(result == (1, 2))
    }
    
    func testCombines() async throws {
        let operation1: AsyncOperation<Int> = .init {
            print("Enter 1")
            try await Task.sleep(for: .seconds(2))
            print("Ending 1")
            return 1
        }
        
        let operation2: AsyncOperation<Int> = .init {
            print("Enter 2")
            try await Task.sleep(for: .seconds(1))
            print("Ending 2")
            return 2
        }
        
        let combined = AsyncOperation.combine([operation1, operation2])
        let result = try await combined.start()
        
        XCTAssert(result == [1, 2])
    }
}

@available(iOS 16, *)
class AsyncOperationQueueTestCases: XCTestCase {
    
    func testOrder() async throws {
        let queue = AsyncOperationQueue()
        
        Task {
            print("Running task 1")
            let result = try await queue.operation {
                print("enter operation 1")
                try await Task.sleep(for: .seconds(2))
                print("after sleep operation 1")
                return 1
            }
            print("Get result \(result)")
        }
        
        await Task.yield()
        
        let task2 = Task {
            print("Running task 2")
            let result = try await queue.operation {
                print("enter operation 2")
                try await Task.sleep(for: .seconds(2))
                print("after sleep operation 2")
                return 2
            }
            print("Get result \(result)")
        }
        
        _ = await task2.result
    }
    
    func testConcurrentQueue() async throws {
        let queue = AsyncOperationQueue(mode: .concurrent(limit: 2))
        let expect = XCTestExpectation()
        
        for i in 0...10 {
            Task {
                print("Running task \(i)")
                let result = try await queue.operation {
                    print("enter operation \(i)")
                    try await Task.sleep(for: .seconds(2))
                    print("after sleep operation \(i)")
                    return i
                }
                print("Get result \(result)")
                if result == 10 {
                    expect.fulfill()
                }
            }
            try await Task.sleep(for: .seconds(0.2))
        }
        
        await fulfillment(of: [expect])
    }
}
