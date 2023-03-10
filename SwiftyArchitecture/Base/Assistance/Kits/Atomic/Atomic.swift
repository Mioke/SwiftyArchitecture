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

public final class RwLock {
    
    private var _lock: pthread_rwlock_t = .init()
    
    public init() {
        pthread_rwlock_init(&_lock, nil)
    }
    
    @discardableResult
    public func readLock() -> Bool {
        pthread_rwlock_rdlock(&_lock) == 0
    }
    
    @discardableResult
    public func writeLock() -> Bool {
        pthread_rwlock_wrlock(&_lock) == 0
    }
    
    public func tryReadLock() throws -> Void {
        let status = pthread_rwlock_tryrdlock(&_lock)
        if status == EBUSY || status == EINVAL || status == EDEADLK {
            throw todo_error()
        }
    }
    
    public func tryWriteLock() throws -> Void {
        let status = pthread_rwlock_trywrlock(&_lock)
        if status == EBUSY || status == EINVAL || status == EDEADLK {
            throw todo_error()
        }
    }
    
    @discardableResult
    public func unlock() -> Bool {
        let status = pthread_rwlock_unlock(&_lock)
        // Error: EINVAL (not initialized), EPERM (doesn't own the lock)
        return status == 0
    }
    
    public func write<T>(_ closure: () -> T) -> T {
        let rst = writeLock(); defer { if rst { unlock() } }
        return closure()
    }
    
    public func read<T>(_ closure: () -> T) -> T {
        let rst = readLock(); defer { if rst { unlock() } }
        return closure()
    }
    
    deinit {
        pthread_rwlock_destroy(&_lock)
    }
}


/** Wrapper of a value to protect it from data race.
 @Discussion:
 But this can't ensure the result is correct and atomic, for example:
  ```swift
  @ThreadSafe
  var array: [Int] = []
 
  queue1.async {
      self.array += [1]
  }
  queue2.async {
      self.array += [1]
  }
 ```
 The result could be randomly different. So this wrapper only keep the value type property from crash when access and
 modified from multiple threads.
 */
@propertyWrapper
final public class ThreadSafe<T> {
    private var value: T
    private let _lock: RwLock = .init()
    
    public var wrappedValue: T {
        get {
            return _lock.read { return value }
        }
        set {
            _lock.write { value = newValue }
        }
    }
    
    public init(wrappedValue: T) {
        self.value = wrappedValue
    }
}

final public class Atomic<T> {
    private var _value: T
    private let _lock: RwLock = .init()
    
    public init(value: T) {
        self._value = value
    }
    
    @discardableResult
    public func modify<Result>(_ action: (inout T) -> Result) -> Result {
        _lock.write {
            action(&_value)
        }
    }
    
    @discardableResult
    public func swap(_ newValue: T) -> T {
        modify { value in
            let oldValue = value
            value = newValue
            return oldValue
        }
    }
    
    public var value: T {
        _lock.read {
            let copy = _value
            return copy
        }
    }
    
    public var unsafeValue: T {
        let copy = _value
        return copy
    }
}
