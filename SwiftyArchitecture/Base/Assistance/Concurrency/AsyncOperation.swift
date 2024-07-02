//
//  Combine.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/6/25.
//

import Foundation
#if canImport(_Concurrency)
import _Concurrency

// MARK: - AsyncOperation

/// A wrapper of an asynchronous operation can produce a result value, the operation can be only execute once.
/// - Note: Wish to make it like: `AsyncOperation<Success, Failure>` but the initial closure throws an anonymous error
/// type
public struct AsyncOperation<Success> {
    public typealias Operation = () async throws -> Success
    
    public enum Error: Swift.Error, Equatable {
        case started
        case executed
    }
    
    enum State {
        case waiting, running ,finished
    }
    
    let operation: Operation
    
    @ThreadSafe
    var state: State = .waiting
    
    /// Initilaization method.
    /// - Parameter operation: The operation which will be wrapped.
    public init(operation: @escaping Operation) {
        self.operation = operation
    }
    
    /// Start this operation. May throws `AsyncOperation.Error` when attemping start a running operation, and `rethrows`
    /// the error which operation throws.
    /// - Returns: The operation's result.
    public func start() async throws -> Success {
        try _state.write { state in
            if state == .finished { throw Error.executed }
            if state == .running { throw Error.started }
            state = .running
        }
        defer { state = .finished }
        return try await self.operation()
    }
}

extension AsyncOperation {
    
    /// Flat map to a new `AyncOperation`, usally can chain two operations together.
    /// - Parameter conversion: The new operation producer.
    /// - Returns: The chained operation.
    public func flatMap<T>(_ conversion: @escaping (Success) throws -> AsyncOperation<T>) -> AsyncOperation<T> {
        return .init {
            let result = try await self.start()
            let next = try conversion(result)
            return try await next.start()
        }
    }
    
    /// Map the result to a new value.
    /// - Parameter conversion: The result conversion closure.
    /// - Returns: The result mapped operation.
    public func map<T>(_ conversion: @escaping (Success) throws -> T) -> AsyncOperation<T> {
        return .init {
            let result = try await self.start()
            return try conversion(result)
        }
    }
    
    /// Combine current operation with another operation.
    /// - Parameter operation: Another operation.
    /// - Returns: The combined operation.
    public func combine<T>(_ operation: AsyncOperation<T>) -> AsyncOperation<(Success, T)> {
        return .init {
            async let myResult = self.start()
            async let otherResult = operation.start()
            return (try await myResult, try await otherResult)
        }
    }
    
    /// Combine multiple operations together and get their results in once. All the operations will run asynchrounously.
    /// - Parameter operations: The operations going to combined.
    /// - Returns: The combined operation.
    public static func combine(_ operations: [AsyncOperation<Success>]) -> AsyncOperation<[Success]> {
        return .init {
            return try await operations.concurrentMap { op in
                try await op.start()
            }
        }
    }
}

// MARK: - AsyncOperationQueue

/// An operation queue to run `AsyncOperation`.
final public class AsyncOperationQueue {
    
    /// The operation's state.
    public enum State: Equatable {
        case running(concurrentCount: Int)
        case waiting
    }
    
    /// The operation's concurrency mode.
    public enum Mode {
        case serial
        case concurrent(limit: Int)
    }
    
    /// Concurrency mode.
    public private(set) var mode: Mode
    /// Current state.
    public private(set) var state: AsyncOperationQueue.State = .waiting
    
    @ThreadSafe
    var queue: [(id: UUID, continuation: CheckedContinuation<Void, Never>)] = []
    
    /// Intialization. Not suggest to use `.concurrent(limit: 1)` for serial execution, the `.serial` mode will have
    /// better performance.
    /// - Parameter mode: The concurrency mode of this operation queue, default is `.serial`
    public init(mode: Mode = .serial) {
        self.mode = mode
    }
    
    /// Enqueue an operation and wait for its result.
    /// - Parameter operation: The operation will be enqueued.
    /// - Returns: The operation's result.
    public func operation<S>(_ operation: AsyncOperation<S>) async throws -> S {
        await withCheckedContinuation { continuation in
            _queue.write { q in
                q.append((id: UUID(), continuation: continuation))
                processNextIfNeeded(queue: &q)
            }
        }
        defer {
            _queue.write { q in
                handleCompletion()
                processNextIfNeeded(queue: &q)
            }
        }
        return try await operation.start()
    }
    
    /// Enqueue an operation and wait for its result.
    /// - Parameter block: The operation's build block.
    /// - Returns: The operation's result.
    public func operation<S>(block: @escaping AsyncOperation<S>.Operation) async throws -> S {
        let asyncOperation: AsyncOperation<S> = .init(operation: block)
        return try await operation(asyncOperation)
    }
    
    // MARK: - Internal functions.
    
    func processNextIfNeeded(queue: inout [(id: UUID, continuation: CheckedContinuation<Void, Never>)]) {
        if case .serial = mode {
            processSerial(queue: &queue)
        } else {
            processConcurrent(queue: &queue)
        }
    }
    
    func processSerial(queue: inout [(id: UUID, continuation: CheckedContinuation<Void, Never>)]) {
        guard case .waiting = state else { return }
        guard let head = queue.isEmpty ? nil : queue.removeFirst() else { return }
        state = .running(concurrentCount: 1)
        head.continuation.resume(returning: ())
    }
    
    func processConcurrent(queue: inout [(id: UUID, continuation: CheckedContinuation<Void, Never>)]) {
        guard case .concurrent(let limit) = mode else {
            return
        }
        let concurrentCount = state.runningCount() ?? 0
        if state != .waiting && concurrentCount >= limit {
            return
        }
        guard let head = queue.isEmpty ? nil : queue.removeFirst() else { return }
        state = .running(concurrentCount: concurrentCount + 1)
        head.continuation.resume(returning: ())
    }
    
    func handleCompletion() -> Void {
        if case .serial = mode {
            state = .waiting
        } else if case .running(let concurrentCount) = state {
            state = (concurrentCount - 1 > 0) ? .running(concurrentCount: concurrentCount - 1) : .waiting
        }
    }
}

extension AsyncOperationQueue.State {
    func runningCount() -> Int? {
        guard case .running(let concurrentCount) = self else {
            return nil
        }
        return concurrentCount
    }
}

#endif
