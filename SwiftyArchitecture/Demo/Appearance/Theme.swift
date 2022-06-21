//
//  Theme.swift
//  SAD
//
//  Created by KelanJiang on 2022/6/21.
//  Copyright © 2022 KleinMioke. All rights reserved.
//

import UIKit
import SwiftUI

struct Theme<T> {
    let resource: T
    init(resource: T) {
        self.resource = resource
    }
    
    func transform<U>(to: U.Type) -> Theme<U>? {
        guard let value = self.resource as? U else { return nil }
        return .init(resource: value)
    }
}

class ThemeUI {
    static var current: Theme<Colors> = .init(resource: DynamicColors())
}

protocol Colors {
    var text: UIColor { get }
    var background: UIColor { get }
}

class DynamicColors: Colors {
    
    enum Settings: Int {
        case followSystem = 0
        case light
        case dark
        
        func toStyle() -> UIUserInterfaceStyle {
            switch self {
            case .dark: return .dark
            case .light: return .light
            case .followSystem: return .unspecified
            }
        }
    }
    
    var currentSetting: Settings = .followSystem {
        didSet {
            UIView.animate(withDuration: 0.2, delay: 0, options: []) {
                UIApplication.shared.windows.forEach { window in
                    window.overrideUserInterfaceStyle = self.currentSetting.toStyle()
                }
            }
        }
    }
    
    func create(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor.init { [weak self] trait in
            guard let self = self else { return light }
            switch self.currentSetting {
            case .light:
                return light
            case .dark:
                return dark
            case .followSystem:
                return trait.userInterfaceStyle == .dark ? dark: light
            }
        }
    }
    
    var text: UIColor {
        return create(light: .label, dark: .white)
    }
    
    var background: UIColor {
        return create(light: .white, dark: .black)
    }
    
}

extension Theme where T == DynamicColors {
    func update(setting: DynamicColors.Settings) {
        self.resource.currentSetting = setting
    }
}
