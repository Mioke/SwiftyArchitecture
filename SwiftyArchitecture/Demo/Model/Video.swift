//
//  Video.swift
//  SAD
//
//  Created by KelanJiang on 2021/10/26.
//  Copyright © 2021 KleinMioke. All rights reserved.
//

import UIKit

struct Video: Codable {
    
    enum State: String, Codable {
        case unknown, streaming, archived
    }
    
    let name: String
    
//    @CodableDefault(defaultValue: .unknown)
    var state: Video.State = .unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.state = try container.decodeIfPresent(Video.State.self, forKey: .state) ?? self.state // not a good solution
    }
}

@propertyWrapper class CodableDefault<T: Codable>: Codable {
    var defaultValue: T
    
    var value: T?
    var wrappedValue: T {
        get { return value ?? defaultValue }
        set { value = newValue }
    }
    
    init(wrappedValue: T? = nil, defaultValue: T) {
        value = wrappedValue
        self.defaultValue = defaultValue
    }
}

