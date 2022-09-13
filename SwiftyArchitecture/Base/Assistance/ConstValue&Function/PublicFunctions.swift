//
//  publicFunctions.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/30.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

/**
 代码区块区分.
 
 - parameter name:    区块功能描述
 - parameter closure: 执行功能
 */
public func scope(_ name: String, closure: () -> ()) -> Void {
    closure()
}

public func doOnMainQueue(_ block: @escaping () -> (), async: Bool = false) -> Void {
    if !async && Thread.current.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}

public protocol DataConversion {
    func data() throws -> Data
    static func object(from data: Data) throws -> Self
}

public extension DataConversion where Self: Codable {
    func data() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    static func object(from data: Data) throws -> Self {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}

public final class WeakObject<T: AnyObject> {
    weak var reference: T?
}
