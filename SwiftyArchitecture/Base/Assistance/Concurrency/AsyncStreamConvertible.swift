//
//  AsyncStreamConvertible.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/7/1.
//

#if canImport(_Concurrency)
import Foundation

// NOTE: - Copy from pointfree: https://github.com/pointfreeco/swift-concurrency-extras

extension AsyncStream {
    /// Produces an `AsyncStream` from an `AsyncSequence` by consuming the sequence till it
    /// terminates, ignoring any failure.
    ///
    /// Useful as a kind of type eraser for live `AsyncSequence`-based dependencies.
    ///
    /// For example, your feature may want to subscribe to screenshot notifications. You can model
    /// this as a dependency client that returns an `AsyncStream`:
    ///
    /// ```swift
    /// struct ScreenshotsClient {
    ///   var screenshots: () -> AsyncStream<Void>
    ///   func callAsFunction() -> AsyncStream<Void> { self.screenshots() }
    /// }
    /// ```
    ///
    /// The "live" implementation of the dependency can supply a stream by erasing the appropriate
    /// `NotificationCenter.Notifications` async sequence:
    ///
    /// ```swift
    /// extension ScreenshotsClient {
    ///   static let live = Self(
    ///     screenshots: {
    ///       AsyncStream(
    ///         NotificationCenter.default
    ///           .notifications(named: UIApplication.userDidTakeScreenshotNotification)
    ///           .map { _ in }
    ///       )
    ///     }
    ///   )
    /// }
    /// ```
    ///
    /// While your tests can use `AsyncStream.makeStream` to spin up a controllable stream for tests:
    ///
    /// ```swift
    /// func testScreenshots() {
    ///   let screenshots = AsyncStream.makeStream(of: Void.self)
    ///
    ///   let model = withDependencies {
    ///     $0.screenshots = { screenshots.stream }
    ///   } operation: {
    ///     FeatureModel()
    ///   }
    ///
    ///   XCTAssertEqual(model.screenshotCount, 0)
    ///   screenshots.continuation.yield()  // Simulate a screenshot being taken.
    ///   XCTAssertEqual(model.screenshotCount, 1)
    /// }
    /// ```
    ///
    /// - Parameter sequence: An async sequence.
    public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        let lock = NSLock()
        var iterator: S.AsyncIterator?
        self.init {
            lock.withLock {
                if iterator == nil {
                    iterator = sequence.makeAsyncIterator()
                }
            }
            return try? await iterator?.next()
        }
    }
    
    /// An `AsyncStream` that never emits and never completes unless cancelled.
    public static var never: Self {
        Self { _ in }
    }
    
    /// An `AsyncStream` that never emits and completes immediately.
    public static var finished: Self {
        Self { $0.finish() }
    }
}

extension AsyncSequence {
    /// Erases this async sequence to an async stream that produces elements till this sequence
    /// terminates (or fails).
    public func eraseToStream() -> AsyncStream<Element> {
        AsyncStream(self)
    }
}

extension AsyncThrowingStream where Failure == Error {
    /// Produces an `AsyncThrowingStream` from an `AsyncSequence` by consuming the sequence till it
    /// terminates, rethrowing any failure.
    ///
    /// - Parameter sequence: An async sequence.
    public init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        let lock = NSLock()
        var iterator: S.AsyncIterator?
        self.init {
            lock.withLock {
                if iterator == nil {
                    iterator = sequence.makeAsyncIterator()
                }
            }
            return try await iterator?.next()
        }
    }
    
    /// An `AsyncThrowingStream` that never emits and never completes unless cancelled.
    public static var never: Self {
        Self { _ in }
    }
    
    /// An `AsyncThrowingStream` that completes immediately.
    ///
    /// - Parameter error: An optional error the stream completes with.
    public static func finished(throwing error: Failure? = nil) -> Self {
        Self { $0.finish(throwing: error) }
    }
}

extension AsyncSequence {
    /// Erases this async sequence to an async throwing stream that produces elements till this
    /// sequence terminates, rethrowing any error on failure.
    public func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream(self)
    }
}




#endif
