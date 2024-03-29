//
//  Lazy.swift
//  MIOSwiftyArchitecture
//
//  Created by Klein on 2024/3/29.
//

import Foundation

/// Lazify the wrapped propterty, protect the thread safety of the initialization process.
/// - Limitations: Only can be used in reference type (class or actor).
@propertyWrapper
public struct Lazify<Enclosing, Value> {
    let lock: UnfairLock = .init()
    
    // For the enclosing instance information, can check this article for detail: 
    // https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/
    public static subscript(
        _enclosingInstance instance: Enclosing,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Enclosing, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Enclosing, Self>
    ) -> Value {
        get {
            var wrapper = instance[keyPath: storageKeyPath]
            if let x = wrapper.storage {
                return x
            }
            return wrapper.lock.around {
                if let x = wrapper.storage {
                    return x
                }
                let temp = instance[keyPath: wrapper.initialiserKeyPath]
                wrapper.storage = temp
                instance[keyPath: storageKeyPath] = wrapper
                return temp
            }
        }
        
        set {
            instance[keyPath: storageKeyPath].storage = newValue
        }
    }

    @available(*, unavailable, message: "This property wrapper can only be used in classes.")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }
    
    public private(set) var storage: Value?
    public let initialiserKeyPath: KeyPath<Enclosing, Value>
    
    /// The initialiser of property wrapper ``Lazify``, make the property as a lazy property, initialise when the first
    /// time read it, and have a thread safety assurrance.
    /// - Parameters:
    ///   - initialiserKeyPath: The key path which should be a computed property to produce the value of this lazy
    ///    property stored.
    public init(initialiserKeyPath: KeyPath<Enclosing, Value>) {
        self.initialiserKeyPath = initialiserKeyPath
    }
}

