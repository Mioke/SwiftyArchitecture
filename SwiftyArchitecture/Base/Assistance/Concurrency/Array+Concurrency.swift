//
//  Array+Concurrency.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/7/2.
//

import Foundation
#if canImport(_Concurrency)
import _Concurrency

extension Array {
    
    ///  Returns an array containing the results of mapping the given closure over the sequence's elements. The mapping
    ///  closure is asynchrounous function and the trasnform process will await the results one by one.
    /// - Parameter conversion: The transform conversion closure.
    /// - Returns: An array containing the transformed elements of this sequence.
    public func asyncMap<T>(_ conversion: (Element) async throws -> T) async rethrows -> [T] {
        var results: [T] = []
        for item in self {
            results.append(try await conversion(item))
        }
        return results
    }
    
    ///  Returns an array containing the results of mapping the given closure over the sequence's elements. The mapping
    ///  closure is asynchrounous function, and different from ``asyncMap(_:)`` this function will run all the
    ///  conversions asynchronously.
    /// - Parameter conversion: The transform conversion closure.
    /// - Returns: An array containing the transformed elements of this sequence.
    public func concurrentMap<T>(_ conversion: @escaping (Element) async throws -> T) async throws -> [T] {
        var results: [T] = []
        let tasks = map { item in
            Task { try await conversion(item) }
        }
        for task in tasks {
            results.append(try await task.value)
        }
        return results
    }
}

#endif
