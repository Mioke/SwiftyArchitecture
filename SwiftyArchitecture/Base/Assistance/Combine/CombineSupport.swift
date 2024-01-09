//
//  CombineSupport.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2023/7/12.
//

import Foundation
import Combine


@dynamicMemberLookup
public struct CombineContext<T> {
    public let base: T
    
    public init(base: T) {
        self.base = base
    }
    
    public subscript<Property>(
        dynamicMember keyPath: ReferenceWritableKeyPath<T, Property>
    ) -> AnyPublisher<Property, Never> where T: NSObject {
        base.publisher(for: keyPath).eraseToAnyPublisher()
    }
}

public protocol CombineCompatible {
    associatedtype CombineBase
    
    var combine: CombineContext<CombineBase> { get set }
    static var combine: CombineContext<CombineBase>.Type { get set }
}

public extension CombineCompatible {
    
    var combine: CombineContext<Self> {
        get { CombineContext(base: self) }
        set { }
    }
    
    static var combine: CombineContext<Self>.Type {
        get { CombineContext<Self>.self }
        set { }
    }
}

extension NSObject: CombineCompatible { }
