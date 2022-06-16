//
//  Atomic.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/6/9.
//

import Foundation
import os

public final class UnfairLock {
    private let _lock: os_unfair_lock_t
    
    init() {
        _lock = .allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }
    
    public func lock() {
        os_unfair_lock_lock(_lock)
    }
    
    public func unlock() {
        os_unfair_lock_unlock(_lock)
    }
    
    public func `try`() -> Bool {
        return os_unfair_lock_trylock(_lock)
    }
    
    deinit {
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }
}

@propertyWrapper
public struct Atomic<T> {
    private var value: T
    private let _lock: UnfairLock = .init()
    
    public var wrappedValue: T {
        get {
            _lock.lock(); defer { _lock.unlock() }
            return value
        }
        set {
            _lock.lock(); defer { _lock.unlock() }
            value = newValue
        }
    }
    
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
}
