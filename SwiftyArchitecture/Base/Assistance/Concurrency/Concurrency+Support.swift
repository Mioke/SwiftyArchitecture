//
//  Created by Klein on 2023/6/8.
//

import Foundation
#if canImport(_Concurrency)
import _Concurrency

// MARK: - AsyncProperty

/// For the feature like `Property<T>` in `ReactiveSwift`
@available(iOS 13.0, *)
public class AsyncProperty<T> {
    
    let multicaster: AsyncMulticast<T> = .init(bufferSize: 1)
    let initialValue: T
    
    /// Initialization
    /// - Parameter wrappedValue: initial value.
    public init(initialValue: T) {
        self.initialValue = initialValue
    }
    
    public var value: T {
        get {
            return multicaster.lastElement() ?? initialValue
        }
    }
    
    public func update(_ newValue: T) {
        multicaster.cast(newValue)
    }
    
    /// Subscribing the changes of this property.
    /// - Important: the token should be stored some where, otherwise the subscibed stream will be invalid immediately.
    /// - Returns: An async stream and it's invalidation token.
    public func subscribe() -> (AsyncStream<T>, UnsubscribeToken) {
        return multicaster.subscribe()
    }
}

// MARK: - AsyncThrowingSignalStream

/// A signal stream similiar to `AsyncThrowingStream`, but a little different from it.
/// 1. Can await in multiple tasks, and `wait(for:)` can only receive signal once.
/// 2. Send `error` to all waiting callers.
/// 3. Won't terminate when receiving an `error`
/// 4. Send `haventWaitedForValue` error when stream is off.
/// 5. If there's a wait in the stream, the stream won't get deallocated, please call `invalid()` first
///    before relase a stream.
@available(iOS 13, *)
public class AsyncThrowingSignalStream<T> {
    
    public enum SignalError: Swift.Error {
        case haventWaitedForValue
    }
    
    private var continuations: [(condition: (T) -> Bool, continuation: CheckedContinuation<T, any Error>)] = []
    
    public init() { }
    
    /// Try await a value signal
    /// - Parameter signalCondition: A condition to determine whether the value is what caller waiting for.
    /// - Returns: The value.
    public func wait(for signalCondition: @escaping (T) -> Bool) async throws -> T {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            continuations.append((condition: signalCondition, continuation: continuation))
        }
    }
    
    /// Send a value into this stream.
    /// - Parameter signal: A value.
    public func send(signal: T) {
        continuations.removeAll(where: { (condition: (T) -> Bool, continuation: CheckedContinuation<T, Error>) in
            if condition(signal) {
                continuation.resume(returning: signal)
                return true
            }
            return false
        })
    }
    
    /// Send an error to all waiting caller.
    /// - Parameter error: An error.
    public func send(error: Error) {
        continuations.removeAll { (condition: (T) -> Bool, continuation: CheckedContinuation<T, Error>) in
            continuation.resume(throwing: error)
            return true
        }
    }
    
    /// Invalidate current stream and remove all waits.
    /// - Important: This stream won't ge deinit when there is any wait in the stream. So invalid when you
    ///              want to release a stream or add `invalid()` in the owner's `deinit`.
    public func invalid() {
        continuations.removeAll { (condition: (T) -> Bool, continuation: CheckedContinuation<T, Error>) in
            continuation.resume(throwing: SignalError.haventWaitedForValue)
            return true
        }
    }
    
    deinit {
        invalid()
    }
}

// MARK: - AsyncMulticast

@available(iOS 13, *)
protocol Unsubscribable: AnyObject {
    func unsubscribe(with token: UnsubscribeToken)
}

@available(iOS 13, *)
public class UnsubscribeToken {
    weak var multicaster: (any Unsubscribable)?
    
    init(multicaster: any Unsubscribable) {
        self.multicaster = multicaster
    }
    /// Unsubscribe from the multicaster.
    public func unsubscribe() {
        multicaster?.unsubscribe(with: self)
    }
    
    deinit {
        unsubscribe()
    }
}

/// Multicast values to many observers, observers can await values over time.
@available(iOS 13, *)
public class AsyncThrowingMulticast<T>: Unsubscribable {
    
    typealias Subscriber = (T) -> Void
    
    @ThreadSafe
    var subscribers: [ObjectIdentifier: (Subscriber, AsyncThrowingStream<T, Error>.Continuation)] = [:]
    
    public let bufferSize: Int
    
    @ThreadSafe
    public private(set) var buffer: [T] = []
    
    public init(bufferSize: Int = 1) {
        self.bufferSize = bufferSize
    }
    
    public func lastElement() -> T? {
        return _buffer.read { $0.last }
    }
    
    /// Subscribe from this multicaster.
    /// - Parameters:
    ///   - condition: Optional, this condition can help to filter the cast values.
    /// - Returns: An `AsyncThrowingStream` and an unsubscribe token.
    public func subscribe(where condition: ((T) -> Bool)? = nil) -> (AsyncThrowingStream<T, Error>, UnsubscribeToken) {
        let cancelToken = UnsubscribeToken(multicaster: self)
        let id = ObjectIdentifier(cancelToken)
        
        return (
            .init { continuation in
                let subscriber: Subscriber = { value in
                    if condition == nil || condition?(value) == true {
                        continuation.yield(value)
                    }
                }
                _subscribers.write { s in
                    s[id] = (subscriber, continuation)
                }
                continuation.onTermination = { [weak self] termination in
                    guard let self else { return }
                    _subscribers.write { s -> Void in
                        s[id] = nil
                    }
                }
            },
            cancelToken
        )
    }
    
    /// Unsubscribe from this multicaster.
    /// - Parameter subscriber: Who is unsubscribing.
    func unsubscribe(with token: UnsubscribeToken) {
        let id = ObjectIdentifier(token)
        let values = _subscribers.write { s -> (Subscriber, AsyncThrowingStream<T, Error>.Continuation)? in
            guard let values = s[id] else { return nil }
            s[id] = nil
            return values
        }
        if let values {
            values.1.finish()
        }
    }
    
    /// Send a value and proadcast it.
    /// - Parameter value: The value.
    public func cast(_ value: T) -> Void {
        _buffer.write {
            $0.append(value)
            if $0.count > bufferSize { $0.removeFirst() }
        }
        let subs = subscribers
        subs.forEach { (_, sub: ((T) -> Void, AsyncThrowingStream<T, Error>.Continuation)) in
            sub.0(value)
        }
    }
    
    /// Send an error to all subscribers, and terminate the for-in loop.
    /// - Parameter error: An error.
    public func cast(error: any Error, keepBuffer: Bool = true) -> Void {
        if !keepBuffer { _buffer.write { $0.removeAll() } }
        let subs = subscribers
        subs.forEach { (_, sub: ((T) -> Void, AsyncThrowingStream<T, Error>.Continuation)) in
            sub.1.finish(throwing: error)
        }
    }
    
    deinit {
        let subs = subscribers
        subs.forEach { (_, sub: ((T) -> Void, AsyncThrowingStream<T, Error>.Continuation)) in
            sub.1.finish()
        }
    }
}

@available(iOS 13, *)
public class AsyncMulticast<T>: Unsubscribable {
    
    typealias Subscriber = (T) -> Void
    
    @ThreadSafe
    var subscribers: [ObjectIdentifier: (Subscriber, AsyncStream<T>.Continuation)] = [:]
    
    public let bufferSize: Int
    
    @ThreadSafe
    public private(set) var buffer: [T] = []
    
    public init(bufferSize: Int = 1) {
        self.bufferSize = bufferSize
    }
    
    public func lastElement() -> T? {
        return _buffer.read { $0.last }
    }
    
    /// Subscribe from this multicaster.
    /// - Parameters:
    ///   - subscriber: Who is subscribing.
    ///   - condition: Optional, this condition can help to filter the cast values.
    /// - Returns: An `AsyncThrowingStream`
    public func subscribe(where condition: ((T) -> Bool)? = nil) -> (AsyncStream<T>, UnsubscribeToken) {
        let cancelToken = UnsubscribeToken(multicaster: self)
        let id = ObjectIdentifier(cancelToken)
        return (
            .init { continuation in
                let subscriber: Subscriber = { value in
                    if condition == nil || condition?(value) == true {
                        continuation.yield(value)
                    }
                }
                _subscribers.write { s in
                    s[id] = (subscriber, continuation)
                }
                continuation.onTermination = { [weak self] termination in
                    guard let self else { return }
                    _subscribers.write { s -> Void in
                        s[id] = nil
                    }
                }
            },
            cancelToken
        )
    }
    
    /// Unsubscribe from this multicaster.
    /// - Parameter subscriber: Who is unsubscribing.
    func unsubscribe(with token: UnsubscribeToken) {
        let id = ObjectIdentifier(token)
        let values = _subscribers.write { s -> (Subscriber, AsyncStream<T>.Continuation)? in
            guard let values = s[id] else { return nil }
            s[id] = nil
            return values
        }
        if let values {
            values.1.finish()
        }
    }
    
    /// Send a value and proadcast it.
    /// - Parameter value: The value.
    public func cast(_ value: T) -> Void {
        _buffer.write {
            $0.append(value)
            if $0.count > bufferSize { $0.removeFirst() }
        }
        let subs = subscribers
        subs.forEach { (_, sub: ((T) -> Void, AsyncStream<T>.Continuation)) in
            sub.0(value)
        }
    }
    
    deinit {
        let subs = subscribers
        subs.forEach { (_, sub: ((T) -> Void, AsyncStream<T>.Continuation)) in
            sub.1.finish()
        }
    }
}


// MARK: - Timeout

/// Inherit the current task priority in task hierarchy.
/// - Parameters:
///   - task: The operation.
///   - nanoseconds: Timeout limit in nanosecond.
///   - onTimeout: Timeout handler.
/// - Throws: The error thrown from `operation`
/// - Returns: The result from `operation`
@available(iOS 13.0, *)
public func timeoutTask<T: Sendable>(with nanoseconds: UInt64,
                                     task: @Sendable @escaping () async throws -> T,
                                     onTimeout: @escaping @Sendable () -> Void) async throws -> T {
    let task = Task(operation: task)
    return try await task.value(timeout: nanoseconds, onTimeout: onTimeout)
}

@available(iOS 13.0, *)
public extension Task where Failure == any Error {
    
    /// The task generated errors using in custom `Task` extension.
    enum CustomError: Error {
        case capturingObjectReleased
        case timeout
    }
    
    /// Get task's success value with a timeout limition.
    /// - Important: If the task is a computationally-intensive process, guarantee to add `Task.checkCancellaction()`
    /// and `Task.yield()` to check the task whether has been cancelled already. ~~Or the timeout block won't get called
    /// immediately but until the time of the task has a chance to check cancelled, for example calling other legecy
    /// API like `Task.sleep`, `URLSessoin.data` etc.~~
    /// - Important: When timeout there will be raised a "CustomError.timeout".
    /// - Parameters:
    ///   - nanoseconds: Timeout limition
    ///   - onTimeout: Timeout handler.
    /// - Returns: Success value.
    func value(timeout nanoseconds: UInt64, onTimeout: (@Sendable () -> Void)? = nil) async throws -> Success {
        return try await withCheckedThrowingContinuation { continuation in
            let cooperateTask = Task<Void, Never> {
                do {
                    try await Task<Never, Never>.sleep(nanoseconds: nanoseconds)
                    // Task.isCancelled - get the value or an error before timed-out.
                    // self.isCancelled - may get cancelled by other process.
                    if !Task<Never, Never>.isCancelled {
                        onTimeout?()
                        continuation.resume(throwing: CustomError.timeout)
                        self.cancel()
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            Task<Void, Never> {
                do {
                    continuation.resume(returning: try await self.value)
                } catch {
                    if !self.isCancelled { continuation.resume(throwing: error) }
                }
                cooperateTask.cancel()
            }
        }
    }
    
    /// Get task's success value with a timeout duration limition.
    /// - Important: If the task is a computationally-intensive process, guarantee to add `Task.checkCancellaction()`
    /// and `Task.yield()` to check the task whether has been cancelled already, or the task may run infinitely.
    /// - Important: When timeout there will be raised a "CustomError.timeout".
    /// - Parameters:
    ///   - duration: Timeout limition in Duration.
    ///   - onTimeout: Timeout handler
    /// - Returns: Success value.
    @available(iOS 16.0, *)
    func value(timeout duration: Duration, onTimeout: (@Sendable () -> Void)? = nil) async throws -> Success {
        return try await withCheckedThrowingContinuation { continuation in
            let cooperateTask = Task<Void, Never> {
                do {
                    try await Task<Never, Never>.sleep(for: duration)
                    // Task.isCancelled - get the value or an error before timed-out.
                    // self.isCancelled - may get cancelled by other process.
                    if !Task<Never, Never>.isCancelled {
                        onTimeout?()
                        continuation.resume(throwing: CustomError.timeout)
                        self.cancel()
                    }
                } catch { 
                    continuation.resume(throwing: error)
                }
            }
            Task<Void, Never> {
                do {
                    continuation.resume(returning: try await self.value)
                } catch {
                    if !self.isCancelled { continuation.resume(throwing: error) }
                }
                cooperateTask.cancel()
            }
        }
    }
    
    // MARK: - Weak capture convinience methods.
    
    /// Create a detached task and weak capture an object for the task operation. (Mostly used in capture `self`)
    /// - Parameters:
    ///   - object: The object to be captured
    ///   - priority: Task priority.
    ///   - operation: Task operation.
    @discardableResult
    static func detached<T>(weakCapturing object: T,
                            priority: TaskPriority? = nil,
                            operation: @escaping (T) async throws -> Success)
    -> Self
    where T: AnyObject, Failure == any Error {
        self.detached(priority: priority) { [weak object] in
            guard let object else { throw CustomError.capturingObjectReleased }
            return try await operation(object)
        }
    }
}

@available(iOS 13.0, *)
public extension Task where Success == Void, Failure == Never {
    static func detached<T: AnyObject>(weakCapturing object: T,
                                       priority: TaskPriority? = nil,
                                       operation: @escaping (T) async -> Void) {
        self.detached(priority: priority, operation: { [weak object] in
            guard let object else { return }
            await operation(object)
        })
    }
}

/// Run tasks one by one, FIFO.
final public class TaskQueue<Element> {
    
    @ThreadSafe
    private var array: Array<TaskItem> = []
    
    private var stream: AsyncMulticast<TaskItem> = .init()
    
    /// The running state, protected by the `array`'s lock, not thread-safe.
    private var isRunning: Bool = false
    
    struct TaskItem {
        let id: String
        let task: () async -> Element
    }
    
    /// Enqueue a task and run it immediately, the finish callback will be called as non-concurrency type.
    /// - Parameters:
    ///   - id: Task id
    ///   - task: The task you want to enqueue.
    ///   - onFinished: Finish callback closure. If the result is nil, that means the `TaskQueue` has already been
    ///   deallocated before this task is finished.
    public func addTask(id: String, _ task: @escaping () async -> Element, onFinished: @escaping (Element?) -> Void) {
        let item = enqueueTask(with: id, task: task)
        let checkInvalidSelf = checkNil(self, throwing: _Concurrency.CancellationError())
        Task { [weak self] in
            await self?.waitUntilAvailable(item: item)()
            let result = try? await checkAround(checkInvalidSelf) { await item.task() }
            onFinished(result)
        }
    }
    
    /// Enqueue a task and wait for it's result.
    /// - Parameters:
    ///   - id: Task id
    ///   - task: The task you want to enqueue.
    /// - Returns: The task's result.
    public func task(id: String, _ task: @escaping () async -> Element) async -> Element {
        let item = enqueueTask(with: id, task: task)
        // The `await`s here will capture `self` and delay the deallocation if the queue has no other owners.
        await waitUntilAvailable(item: item)()
        return await item.task()
    }
    
    /// Enqueue a task and try to run it immediately.
    /// - Parameters:
    ///   - id: Task's id
    ///   - task: The task.
    /// - Returns: The wrapped Task.
    public func enqueueTask(id: String, task: @escaping () async -> Element) -> Task<Element, Error> {
        let item = enqueueTask(with: id, task: task)
        let checkInvalidSelf = checkNil(self, throwing: _Concurrency.CancellationError())
        return .init { [weak self] in
            await self?.waitUntilAvailable(item: item)()
            return try await checkAround(checkInvalidSelf) { await item.task() }
        }
    }
    
    private func enqueueTask(with id: String, task: @escaping () async -> Element) -> TaskItem {
        let item = TaskItem(id: id, task: { [weak self] in
            let result = await task()
            if let self {
                self.isRunning = false
                self.checkNext()
            }
            return result
        })
        _array.write { array in
            array.append(item)
        }
        return item
    }
    
    private func waitUntilAvailable(item: TaskItem) -> () async -> Void {
        // weak capture `self`, otherwise if any signal is waiting, the `TaskQueue` can't be deallocated.
        return { [weak self] in
            guard let (signal, token) = self?.stream.subscribe(where: { $0.id == item.id }) else { return }
            self?.checkNext()
            // Must await here first, then the `stream` can cast the item later.
            for await _ in signal { break }
            token.unsubscribe()
        }
    }
    
    private func checkNext() {
        let next: TaskItem? = _array.write { array in
            // `isRunning` must be protected by the `write`, because this whole logic determine the `isRunning` state.
            guard isRunning == false, let next = array.first else { return nil }
            array.removeFirst()
            isRunning = true
            return next
        }
        guard let next else { return }
        
        // cast asynchrounously, make sure the `cast` is run after `await`.
        Task {
            stream.cast(next)
        }
    }
    
    deinit {
        print("deallocating ...")
    }
}

public typealias ThrowingTaskQueue<Value, E: Swift.Error> = TaskQueue<Swift.Result<Value, E>>


#endif
