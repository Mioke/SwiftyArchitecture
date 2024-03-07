//
//  Created by Klein on 2023/6/8.
//

import Foundation
#if canImport(_Concurrency)
import _Concurrency

// MARK: - AsyncProperty

/// Asynchronous updating a property and suspend the caller using `await`, but if the state is `ready` then it won't
/// suspend the caller. For the feature like `Property<T>` in `ReactiveSwift`
@available(iOS 13.0, *)
public class AsyncProperty<T> {
    
    public enum State {
        case ready, updating
    }
    
    public enum UpdateError: Error {
        case duringUpdating
    }
    
    /// Current state.
    @ThreadSafe
    public private(set) var state: State = .ready
    
    /// a storage contains all task continuations when the value is updating.
    private var continuations: [CheckedContinuation<T, Error>] = []
    
    private var _value: T
    
    /// Initialization
    /// - Parameter wrappedValue: initial value.
    public init(wrappedValue: T) {
        _value = wrappedValue
    }
    
    /// Get the wrapperd value, may await here when there is updating operation running.
    public var value: T {
        get async throws {
            if state == .ready {
                return _value
            }
            return try await withCheckedThrowingContinuation { continuation in
                continuations.append(continuation)
            }
        }
    }
    
    /// Use this function to modify the wrapped value, the state will automatically adjust to corresponding state.
    /// - Parameter operation: Async operation.
    public func update(_ operation: (T) async throws -> T) async throws {
        guard state != .updating else { throw UpdateError.duringUpdating }
        do {
            state = .updating
            _value = try await operation(_value)
            continuations.forEach { $0.resume(returning: _value) }
        } catch {
            continuations.forEach { $0.resume(throwing: error) }
        }
        state = .ready
        continuations.removeAll()
    }
    
    /// Mark this property is updating, block and await all from get value
    public func markUpdating() {
        state = .updating
    }
    
    /// Mark this property is ready, send result to all callers which are waiting for the value.
    public func endUpdating(with result: Swift.Result<T, Error>) {
        guard state == .updating else {
            assertionFailure("AsyncProperty is not updating")
            return
        }
        switch result {
        case .success(let success):
            _value = success
            continuations.forEach { $0.resume(returning: _value) }
        case .failure(let failure):
            continuations.forEach { $0.resume(throwing: failure) }
        }
        state = .ready
        continuations.removeAll()
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
    func unsubscribe(with subscriber: AnyObject)
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

@available(iOS 13, *)
public class AsyncThrowingMulticast<T>: Unsubscribable {
    
    typealias Subscriber = (T) -> Void
    
    @ThreadSafe
    var subscribers: [ObjectIdentifier: (Subscriber, AsyncThrowingStream<T, Error>.Continuation)] = [:]
    
    public init() { }
    
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
    func unsubscribe(with subscriber: AnyObject) {
        let id = ObjectIdentifier(subscriber)
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
        let subs = subscribers
        subs.forEach { (_, sub: ((T) -> Void, AsyncThrowingStream<T, Error>.Continuation)) in
            sub.0(value)
        }
    }
    
    /// Send an error to all subscribers, and terminate the for-in loop.
    /// - Parameter error: An error.
    public func cast(error: any Error) -> Void {
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
    
    public init() { }
    
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
    public func unsubscribe(with subscriber: AnyObject) {
        let id = ObjectIdentifier(subscriber)
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
                                     onTimeout: @Sendable () -> Void) async throws -> T {
    let task = Task(operation: task)
    Task.detached {
        try await Task.sleep(nanoseconds: nanoseconds)
        task.cancel()
    }
    return try await withTaskCancellationHandler(
        operation: {
            do {
                return try await task.value
            } catch {
                if error is CancellationError {
                    onTimeout()
                }
                throw error
            }
        },
        onCancel: { /* won't run here, weird... */})
}

@available(iOS 13.0, *)
public extension Task {
    
    /// Get task's success value with a timeout limition.
    /// - Important: If the task is a computationally-intensive process, guarantee to add `Task.checkCancellaction()`
    /// and `Task.yield()` to check the task whether has been cancelled already. Or the timeout block won't get called
    /// immediately but until the time of the task has a chance to check cancelled, for example calling other legecy
    /// API like `Task.sleep`, `URLSessoin.data` etc.
    /// - Important: When timeout there will be raised a "CancellationError".
    /// - Parameters:
    ///   - nanoseconds: Timeout limition
    ///   - onTimeout: Timeout handler.
    /// - Returns: Success value.
    func value(timeout nanoseconds: UInt64, onTimeout: @Sendable () -> Void) async throws -> Success {
        Task<Void, Error>.detached {
            try await Task<Never, Never>.sleep(nanoseconds: nanoseconds)
            self.cancel()
        }
        return try await withTaskCancellationHandler {
            do {
                return try await self.value
            } catch {
                if error is CancellationError {
                    onTimeout()
                }
                throw error
            }
        } onCancel: { }
    }
    
    /// Get task's success value with a timeout duration limition.
    /// - Important: If the task is a computationally-intensive process, guarantee to add `Task.checkCancellaction()`
    /// and `Task.yield()` to check the task whether has been cancelled already. Or the timeout block won't get called
    /// immediately but until the time of the task has a chance to check cancelled, for example calling other legecy
    /// API like `Task.sleep`, `URLSessoin.data` etc.
    /// - Important: When timeout there will be raised a "CancellationError".
    /// - Parameters:
    ///   - duration: Timeout limition in Duration.
    ///   - onTimeout: Timeout handler
    /// - Returns: Success value.
    @available(iOS 16.0, *)
    func value(timeout duration: Duration, onTimeout: @Sendable () -> Void) async throws -> Success {
        Task<Void, Error>.detached {
            try await Task<Never, Never>.sleep(for: duration)
            self.cancel()
        }
        return try await withTaskCancellationHandler {
            do {
                return try await self.value
            } catch {
                if error is CancellationError {
                    onTimeout()
                }
                throw error
            }
        } onCancel: { }
    }
    
    // MARK: - Weak capture convinience methods.
    /// The task generated errors using in custom `Task` extension.
    enum TaskError: Error {
        case capturingObjectReleased
    }
    
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
            guard let object else { throw TaskError.capturingObjectReleased }
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

#endif
