//
//  CommonModule.swift
//  SAD
//
//  Created by KelanJiang on 2023/4/6.
//  Copyright © 2023 KleinMioke. All rights reserved.
//

import Foundation
import MIOSwiftyArchitecture

public extension ModuleIdentifier {
    static let common: ModuleIdentifier = "com.klein.module.auth"
}

class CommonModule: ModuleProtocol {
    required init() { }
    
    static var moduleIdentifier: MIOSwiftyArchitecture.ModuleIdentifier {
        .common
    }
    
    func moduleDidLoad(with manager: MIOSwiftyArchitecture.ModuleManager) {
        
    }
}

extension CommonModule: ModuleInitiatorProtocol {
    static var identifier: String {
        .common
    }
    
    static var operation: MIOSwiftyArchitecture.Initiator.Operation = {
        navigation = .init(inAppLinkScheme: "sa-interal", universalLinkScheme: "sa", host: "com.mioke.swifty-architecture-demo")
        if let url = Bundle.main.url(forResource: "AppLinkRegistery", withExtension: ".plist") {
            try! navigation?.setRegisteryFile(at: url)
        }
    }
    
    static var priority: MIOSwiftyArchitecture.Initiator.Priority {
        .high
    }
    
    static var dependencies: [String] {
        []
    }
}

public var navigation: Navigation? = nil
