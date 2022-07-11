//
//  Theme.swift
//  SAD
//
//  Created by KelanJiang on 2022/6/21.
//  Copyright © 2022 KleinMioke. All rights reserved.
//

import UIKit
import SwiftUI

class ThemeUI {
    static var themeDidChange: Notification.Name = .init(rawValue: "SwiftyArchitecture.ThemeUI.themeDidChange")
    static var current: some Resource = DynamicResource() {
        didSet { NotificationCenter.default.post(name: themeDidChange, object: nil) }
    }
}

protocol Colors {
    var text: UIColor { get }
    var background: UIColor { get }
}

protocol Icons {
    var appIcon: UIImage { get }
}

protocol Resource {
    associatedtype Color: Colors
    associatedtype Icon: Icons
    
    var color: Color { get }
    var icon: Icon { get }
}

class DynamicColors: Colors {
    
    var text: UIColor {
        return create(light: .label, dark: .white)
    }
    
    var background: UIColor {
        return create(light: .white, dark: .black)
    }
    
    var currentSetting: DynamicResource.Settings = .followSystem
    
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
}

class DynamicIcons: Icons {
    var currentSetting: DynamicResource.Settings = .followSystem
    
    var appIcon: UIImage {
        return .init(named: "launch_swifty_icon")!
    }
}

class DynamicResource: Resource {
    typealias Color = DynamicColors
    typealias Icon = DynamicIcons

    var color: DynamicColors = .init()
    var icon: DynamicIcons = .init()
    
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
            self.color.currentSetting = currentSetting
            self.icon.currentSetting = currentSetting
            
            UIView.animate(withDuration: 0.15, delay: 0, options: []) {
                UIApplication.availableWindows.forEach { window in
                    window.overrideUserInterfaceStyle = self.currentSetting.toStyle()
                }
            }
        }
    }
}
