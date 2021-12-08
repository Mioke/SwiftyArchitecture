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
    
    @CodableDefault
    var state: Video.State?
}

@propertyWrapper class CodableDefault<T: Decodable>: Decodable {
    var value: T?
    
    var wrappedValue: T {
        get { return value! }
        set { self.value = newValue }
    }
    // This would be called when Codable object initializing.
    init(wrappedValue: T) {
        self.value = wrappedValue
    }
}

