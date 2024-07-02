//
//  AsyncMulticast.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/7/2.
//

#if canImport(_Concurrency)
import _Concurrency
import Foundation

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
    ///   - bufferingPolicy: The buffering policy of returning stream.
    /// - Returns: An `AsyncThrowingStream` and an unsubscribe token.
    public func subscribe(
        where condition: ((T) -> Bool)? = nil,
        bufferingPolicy: AsyncThrowingStream<T, Error>.Continuation.BufferingPolicy = .unbounded)
    -> (stream: AsyncThrowingStream<T, Error>, token: UnsubscribeToken) {
        
        let cancelToken = UnsubscribeToken(multicaster: self)
        let id = ObjectIdentifier(cancelToken)
        let make = AsyncThrowingStream<T, Error>.makeStream(bufferingPolicy: bufferingPolicy)
        
        let subscriber: Subscriber = { value in
            if condition == nil || condition?(value) == true {
                make.continuation.yield(value)
            }
        }
        _subscribers.write { s in
            s[id] = (subscriber, make.continuation)
        }
        
        make.continuation.onTermination = { [weak self] termination in
            guard let self else { return }
            _subscribers.write { s -> Void in
                s[id] = nil
            }
        }
        return (stream: make.stream, token: cancelToken)
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

/// Multicast values to many observers, observers can await values over time.
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
    ///   - condition: Optional, this condition can help to filter the cast values.
    ///   - bufferingPolicy: The buffering policy of returning stream.
    /// - Returns: An `AsyncStream` and its finish token.
    public func subscribe(
        where condition: ((T) -> Bool)? = nil,
        bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .unbounded)
    -> (stream: AsyncStream<T>, token: UnsubscribeToken) {
        
        let cancelToken = UnsubscribeToken(multicaster: self)
        let id = ObjectIdentifier(cancelToken)
        let make = AsyncStream<T>.makeStream(bufferingPolicy: bufferingPolicy)
        
        let subscriber: Subscriber = { value in
            if condition == nil || condition?(value) == true {
                make.continuation.yield(value)
            }
        }
        _subscribers.write { s in
            s[id] = (subscriber, make.continuation)
        }
        
        make.continuation.onTermination = { [weak self] termination in
            guard let self else { return }
            _subscribers.write { s -> Void in
                s[id] = nil
            }
        }
        return (stream: make.stream, token: cancelToken)
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

extension AsyncStream {
    
    /// Make a multicaster for this stream. If the task is suspended or released, the multicatser can't receive any
    /// new elements.
    /// - Returns: An observing task and it's multicatster.
    public func makeMulticaster() -> (task: Task<Void, Error>, multicaster: AsyncMulticast<Element>) {
        let multicaster = AsyncMulticast<Element>()
        return (
            task: .init(operation: { [weak multicaster] in
                var iterator = self.makeAsyncIterator()
                while let element = await iterator.next() {
                    multicaster?.cast(element)
                    try Task.checkCancellation()
                    await Task.yield()
                }
            }),
            multicaster: multicaster
        )
    }
}

extension AsyncThrowingStream {
    
    /// Make a throwing multicaster for this stream. If the task is suspended or released, the multicatser can't
    /// receive any new elements.
    /// - Returns: An observing task and it's multicatster.
    public func makeMulticaster() -> (task: Task<Void, Error>, multicaster: AsyncThrowingMulticast<Element>) {
        let multicaster = AsyncThrowingMulticast<Element>()
        return (
            task: .init(operation: { [weak multicaster] in
                var iterator = self.makeAsyncIterator()
                do {
                    while let element = try await iterator.next() {
                        multicaster?.cast(element)
                        // don't catch this cancellation error.
                        try? Task.checkCancellation()
                        await Task.yield()
                    }
                } catch {
                    multicaster?.cast(error: error)
                }
            }),
            multicaster: multicaster
        )
    }
}

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

#endif
