//
//  ModuleManager+Testable.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/5/23.
//

import Foundation

extension ModuleBridge {
    public func inject(instance: ModuleProtocol) -> Bool {
        self.injected[type(of: instance).moduleIdentifier] = instance
        return true
    }
}
