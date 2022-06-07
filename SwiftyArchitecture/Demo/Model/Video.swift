//
//  Video.swift
//  SAD
//
//  Created by KelanJiang on 2021/10/26.
//  Copyright © 2021 KleinMioke. All rights reserved.
//

import UIKit

struct Video: Decodable {
    enum State: String, Decodable {
        case unknown, streaming, archived
    }
    
    let name: String
    
    @CodableDefault(defaultValue: .unknown)
    var state: Video.State
}

@propertyWrapper class CodableDefault<T: Decodable>: Decodable {
    var `default`: T
    var value: T?
    
    var wrappedValue: T {
        get { return value ?? `default` }
        set { self.value = newValue }
    }
    // This would be called when Codable object initializing.
    init(defaultValue: T) {
        self.default = defaultValue
    }
}

