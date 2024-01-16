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
    static var themeResourceDidChange: Notification.Name = .init(rawValue: "SwiftyArchitecture.ThemeUI.themeDidChange")
    static var current: Resource = DynamicResource() {
        didSet { NotificationCenter.default.post(name: themeResourceDidChange, object: nil) }
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
    var color: Colors { get }
    var icon: Icons { get }
}

class DynamicColors: Colors {
    
    unowned var resource: DynamicResource?
    
    init(resource: DynamicResource) {
        self.resource = resource
    }
    
    var text: UIColor {
        return create(light: .label, dark: .white)
    }
    
    var background: UIColor {
        return create(light: .white, dark: .black)
    }
    
    func create(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor.init { [weak self] trait in
            guard let resource = self?.resource else { return light }
            switch resource.currentSetting {
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
    
    unowned var resource: DynamicResource?
    
    init(resource: DynamicResource) {
        self.resource = resource
    }
    
    var appIcon: UIImage {
        return .init(named: "launch_swifty_icon")!
    }
}

class DynamicResource: Resource {
    lazy var color: Colors = DynamicColors.init(resource: self)
    lazy var icon: Icons = DynamicIcons.init(resource: self)
    
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
            UIView.animate(withDuration: 0.15, delay: 0, options: []) {
                UIApplication.availableWindows.forEach { window in
                    window.overrideUserInterfaceStyle = self.currentSetting.toStyle()
                }
            }
        }
    }
}

// MARK: - example for other static resource

class DefaultColors: Colors {
    var text: UIColor {
        return .label
    }
    var background: UIColor {
        return .white
    }
}

class DefaultIcons: Icons {
    var appIcon: UIImage {
        return .init(named: "launch_swifty_icon")!
    }
}

class DefaultResource: Resource {
    var color: Colors = DefaultColors()
    var icon: Icons = DefaultIcons()
}

class TestCaseResources {
    func testSwitchResource() -> Void {
        ThemeUI.current = DefaultResource()
    }
}
