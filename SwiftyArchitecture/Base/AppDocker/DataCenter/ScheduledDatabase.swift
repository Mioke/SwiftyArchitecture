//
//  ScheduledDatabase.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/7/26.
//

import Foundation

public protocol ScheduledDatabase: AnyObject {
    var rwQueue: RwQueue { get set }
    func write<T>(_ execution: (Self) -> T) -> T
    func read<T>(_ execution: (Self) -> T) -> T
    
    func `async`(write execution: @escaping (Self) -> Void)
    func `async`(read execution: @escaping (Self) -> Void)
}

extension ScheduledDatabase {
    
    public func write<T>(_ execution: (Self) -> T) -> T {
        return rwQueue.syncWrite { execution(self) }
    }
    
    public func read<T>(_ execution: (Self) -> T) -> T {
        return rwQueue.syncRead { execution(self) }
    }
    
    public func async(write execution: @escaping (Self) -> Void) {
        rwQueue.write { execution(self) }
    }
    
    public func async(read execution: @escaping (Self) -> Void) {
        rwQueue.read { execution(self) }
    }
}

// Realm doesn't need to conform to `ScheduledDatabase` because it's thread-safe with MVCC:

/**
 - **Don't lock to read:**
   Realm Database's Multiversion Concurrency Control (MVCC) architecture eliminates the need to lock for read operations. The values you read will never be corrupted or in a partially-modified state. You can freely read from realms on any thread without the need for locks or mutexes. Unnecessary locking would be a performance bottleneck since each thread might need to wait its turn before reading.
 - **Avoid writes on the UI thread if you write on a background thread:**
   You can write to a realm from any thread, but there can be only one writer at a time. Consequently, write transactions block each other. A write on the UI thread may result in your app appearing unresponsive while it waits for a write on a background thread to complete. If you are using Device Sync, avoid writing on the UI thread as Sync writes on a background thread.
 - **Don't pass live objects, collections, or realms to other threads:**
   Live objects, collections, and realm instances are thread-confined: that is, they are only valid on the thread on which they were created. Practically speaking, this means you cannot pass live instances to other threads. However, Realm Database offers several mechanisms for sharing objects across threads.
 */
