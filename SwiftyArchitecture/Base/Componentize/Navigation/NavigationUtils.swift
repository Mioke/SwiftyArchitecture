//
//  NavigationUtils.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2023/4/4.
//

import Foundation
import UIKit

extension URL {
    var getHost: String? {
        if #available(iOS 16.0, *) {
            return self.host()
        } else {
            return self.host
        }
    }
    
    var getPath: String {
        if #available(iOS 16.0, *) {
            return self.path()
        } else {
            return self.path
        }
    }
}

extension CharacterSet {
    /// Creates a CharacterSet from RFC 3986 allowed characters.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    public static let fixedURLQueryAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        
        return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
    }()
}

func escape(_ string: String) -> String {
    return string.addingPercentEncoding(withAllowedCharacters: .fixedURLQueryAllowed) ?? string
}

class NavigationUtils {
    static func topPresentingViewController() -> UIViewController? {
        guard let window = applicationWindow(), var controller = window.rootViewController else {
            return nil
        }
        while let presenting = controller.presentedViewController, !presenting.isBeingDismissed {
            controller = presenting
        }
        return controller
    }
    
    static func frontmostViewController() -> UIViewController? {
        guard let controller = topPresentingViewController() else { return nil }
        
        func _frontmost(of vc: UIViewController) -> UIViewController? {
            if let controller = vc as? UINavigationController {
                return controller.topViewController ?? controller
            } else if let controller = vc as? UITabBarController, let selected = controller.selectedViewController {
                return _frontmost(of: selected)
            } else {
                return vc
            }
        }
        return _frontmost(of: controller)
    }
    
    static func applicationWindow() -> UIWindow? {
        if #available(iOS 15.0, *),
           let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 as? UIWindowScene != nil }) as? UIWindowScene,
           let key = windowScene.keyWindow {
            return key
        }
        return UIApplication.shared.delegate?.window ?? nil
    }
}
