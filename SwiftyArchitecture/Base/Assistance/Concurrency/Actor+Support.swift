//
//  Actor+Support.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/1/4.
//

import Foundation

// Copied from Realm

@available(macOS 10.15, tvOS 13.0, iOS 13.0, watchOS 6.0, *)
public extension Actor {
    func verifier() -> (@Sendable () -> Void) {
#if swift(>=5.9)
        // When possible use the official API for actor checking
        if #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *) {
            return {
                self.preconditionIsolated()
            }
        }
#endif
        
        // This exploits a hole in Swift's type system to construct a function
        // which is isolated to the current actor, and then casts away that
        // information. This results in runtime warnings/aborts if it's called
        // from outside the actor when actor data race checking is enabled.
        let fn: () -> Void = { _ = self }
        return unsafeBitCast(fn, to: (@Sendable () -> Void).self)
    }
    
    // Asynchronously invoke the given block on the actor. This takes a
    // non-sendable function because the function is invoked on the same actor
    // it was defined on, and just goes through some hops in between.
    nonisolated func invoke(_ fn: @escaping () -> Void) {
        let fn = unsafeBitCast(fn, to: (@Sendable () -> Void).self)
        Task {
            await doInvoke(fn)
        }
    }
    
    private func doInvoke(_ fn: @Sendable () -> Void) {
        fn()
    }
    
    // A helper to invoke a regular isolated sendable function with this actor
    func invoke<T: Sendable>(_ fn: @Sendable (isolated Self) async throws -> T) async rethrows -> T {
        try await fn(self)
    }
}

public extension MainActor {
    /// Explicitly mark this function is running in a asynchronized way.
    nonisolated static func `async`(fn: @escaping () -> Void) {
        MainActor.shared.invoke(fn)
    }
}
