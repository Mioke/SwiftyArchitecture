//
//  NetworkCache.swift
//  swiftArchitecture
//
//  Created by Mioke on 15/12/29.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import KMCache

class NetworkCache: NSObject {
    
    static let memoryCache = NetworkCache()
    
    private let cache = KMCache(type: .ReleaseByTime)
    
    override init() {
        super.init()
        self.cache.needRefreshCacheWhenUsed = false
        self.cache.maxCount = 20
    }
    
    func setObject(object: NSObjectProtocol, forKey key: NSObjectProtocol) {
        self.cache.setCacheObject(object, forKey: key)
    }
    
    func objectForKey(key: NSObjectProtocol) -> NSObjectProtocol? {
        return self.cache.objectForKey(key)
    }
    
    func size() -> UInt {
        return self.cache.size()
    }
}
