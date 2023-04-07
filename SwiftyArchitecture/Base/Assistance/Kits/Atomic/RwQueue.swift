//
//  RwQueue.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/6/16.
//

import Foundation

/// The `RwQueue` is only be used in a simple way because it's a heavy work when enqueue actions and switch the threads.
/// So if `RwQueue` contains huge amount of work to do, it may leads to unexpected behavior and bad performance.
public class RwQueue {
    
    public let queue: DispatchQueue
    
    public init(qos: DispatchQoS = .default, label: String? = nil) {
        self.queue = .init(label: "com.mioke.swiftyarchitecture.rwqueue" + (!label.isEmpty ? ".\(label!)" : ""),
                           qos: qos,
                           attributes: .concurrent)
    }
    
    public func read(action: @escaping () -> ()) {
        queue.async(execute: action)
    }
    
    public func write(action: @escaping () -> ()) {
        queue.async(flags: .barrier, execute: action)
    }
    
    public func syncRead<T>(_ closure: () throws -> T) rethrows -> T {
        return try queue.sync(execute: closure)
    }
    
    public func syncWrite<T>(_ closure: () throws -> T) rethrows -> T {
        return try queue.sync(flags: .barrier, execute: closure)
    }
}
