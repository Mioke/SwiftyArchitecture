//
//  RwQueue.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/6/16.
//

import Foundation

public class RwQueue {
    
    private let queue: DispatchQueue
    
    public init(qos: DispatchQoS, label: String? = nil) {
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
    
    public func syncWrite(_ closure: () throws -> Void) rethrows {
        try queue.sync(flags: .barrier, execute: closure)
    }
}

extension Swift.Optional where Wrapped == String {
    @inlinable var isEmpty: Bool {
        switch self {
        case .none:
            return true
        case .some(let value):
            return value.isEmpty
        }
    }
}
