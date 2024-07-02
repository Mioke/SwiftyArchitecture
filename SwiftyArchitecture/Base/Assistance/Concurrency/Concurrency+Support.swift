//
//  Created by Klein on 2023/6/8.
//

import Foundation
#if canImport(_Concurrency)
import _Concurrency

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
}

// MARK: - Weak capture convinience methods.
@available(iOS 13.0, *)
public extension Task where Failure == any Error {
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


#endif
