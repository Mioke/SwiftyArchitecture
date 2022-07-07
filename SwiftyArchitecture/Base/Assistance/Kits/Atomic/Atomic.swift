//
//  Atomic.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/6/9.
//

import Foundation
import os
import Darwin

public final class UnfairLock {
    private let _lock: os_unfair_lock_t
    
    public init() {
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
    
    public func around<T>(_ closure: () -> T) -> T {
        lock(); defer { unlock() }
        return closure()
    }
    
    deinit {
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }
}

@propertyWrapper
public struct Atomic<T> {
    private var value: T
    private let _lock: RwLock = .init()
    
    public var wrappedValue: T {
        get {
            return _lock.read { self.value }
        }
        set {
            _lock.write { self.value = newValue }
        }
    }
    
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
}

public final class RwLock {
    
    private var _lock: pthread_rwlock_t = .init()
    
    public init() {
        pthread_rwlock_init(&_lock, nil)
    }
    
    public func readLock() -> Void {
        pthread_rwlock_rdlock(&_lock)
    }
    
    public func writeLock() -> Void {
        pthread_rwlock_wrlock(&_lock)
    }
    
    public func tryReadLock() throws -> Void {
        let status = pthread_rwlock_tryrdlock(&_lock)
        if status == EBUSY {
            throw todo_error()
        }
    }
    
    public func tryWriteLock() throws -> Void {
        let status = pthread_rwlock_wrlock(&_lock)
        if status == EBUSY {
            throw todo_error()
        }
    }
    
    public func unlock() -> Void {
        pthread_rwlock_unlock(&_lock)
    }
    
    public func write(_ closure: () -> Void) {
        writeLock(); defer { unlock() }
        closure()
    }
    
    public func read<T>(_ closure: () -> T) -> T {
        readLock(); defer { unlock() }
        return closure()
    }
    
    deinit {
        pthread_rwlock_destroy(&_lock)
    }
}
