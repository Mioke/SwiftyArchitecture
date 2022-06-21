//
//  RwQueue.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/6/16.
//

import Foundation

public class RwQueue {
    
    private let queue: DispatchQueue
    
    public init(qos: DispatchQoS) {
        self.queue = .init(label: "com.mioke.swiftyarchitecture.rwqueue",
                           qos: qos,
                           attributes: .concurrent)
    }
    
    public func read(action: @escaping () -> ()) {
        queue.async(execute: action)
    }
    
    public func write(action: @escaping () -> ()) {
        queue.async(flags: .barrier, execute: action)
    }
}
