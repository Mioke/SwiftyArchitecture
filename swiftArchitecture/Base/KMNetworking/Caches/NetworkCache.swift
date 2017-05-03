//
//  NetworkCache.swift
//  swiftArchitecture
//
//  Created by Mioke on 15/12/29.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import KMCache

open class NetworkCache: NSObject {
    
    public static let memoryCache = NetworkCache()
    
    fileprivate let cache = KMCache(type: .releaseByTime)
    
    override init() {
        super.init()
        self.cache.needRefreshCacheWhenUsed = false
        self.cache.maxCount = 20
    }
    
    open func set(object: Any, forKey key: Any) {
        self.cache.setCacheObject(object as! NSObjectProtocol, forKey: key as! NSObjectProtocol)
    }
    
    open func object(forKey key: Any) -> Any? {
        return self.cache.object(forKey: key)
    }
    
    open func size() -> UInt {
        return self.cache.size()
    }
}
