//
//  NetworkCache.swift
//  swiftArchitecture
//
//  Created by Mioke on 15/12/29.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

/// For cache networking's request and response
open class NetworkCache: NSObject {
    
    /// default cache stored in memory
    public static let memoryCache = NetworkCache()
    
//    fileprivate let cache = KMCache(type: .releaseByTime)
    
    override init() {
        super.init()
//        self.cache.needRefreshCacheWhenUsed = false
//        self.cache.maxCount = 20
    }
    
    /// Store object in cache
    ///
    /// - Parameters:
    ///   - object: object to cache
    ///   - key: key to access mapped object
    open func set(object: Any, forKey key: Any) {
//        self.cache.setCacheObject(object as! NSObjectProtocol, forKey: key as! NSObjectProtocol)
    }
    
    /// Get stored object
    ///
    /// - Parameter key: key to access mapped object
    /// - Returns: Object stored in cache, `nil` mean can't find it.
    open func object(forKey key: Any) -> Any? {
//        return self.cache.object(forKey: key)
        return nil
    }
    
    /// Get the current cache stored size
    ///
    /// - Returns: Size of current cached objects
    public func size() -> UInt {
//        return self.cache.size()
        return 0
    }
}
