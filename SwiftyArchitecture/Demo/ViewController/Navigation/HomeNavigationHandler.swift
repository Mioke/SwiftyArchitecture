//
//  HomeNavigationHandler.swift
//  SAD
//
//  Created by KelanJiang on 2023/4/4.
//  Copyright © 2023 KleinMioke. All rights reserved.
//

import Foundation
import MIOSwiftyArchitecture

class HomeNavigationHandler: NavigationModuleHandlerProtocol {
    static func shouldNavigate(to url: MIOSwiftyArchitecture.NavigationURL,
                               decisionHandler: @escaping (MIOSwiftyArchitecture.Navigation.Decision) -> Void) {
        KitLogger.info()
        if let firstPath = url.paths.first, firstPath == "messages" {
//            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                decisionHandler(.pass)
//            }
        } else {
            decisionHandler(.pass)
        }
    }
    
    static func willNavigate(to url: MIOSwiftyArchitecture.NavigationURL) {
        
    }
    
    static func didNavigate(to url: MIOSwiftyArchitecture.NavigationURL) {
        
    }
}
