//
//  LinkParser.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2023/4/6.
//

import Foundation

public struct ConfigKeys {
    public static let presentationMode: String = "_pm"
    public static let animated: String = "_a"
    
    public enum PresentationModeValue: String {
        case push = "push"
        case present = "present"
    }
}

struct LinkParser {
    
    enum ParseError: Error {
        case cannotGenerateUrl
        case notCompatibleToConfig
    }
    
    var universalLinkScheme: String
    var inAppLinkScheme: String
    var host: String
    
    func parse(urlString: String) throws -> NavigationURL {
        guard let navigation = NavigationURL(from: urlString) else {
            throw ParseError.cannotGenerateUrl
        }
        try validate(url: navigation)
        return navigation
    }
    
    func validate(url: NavigationURL) throws {
        guard url.scheme == inAppLinkScheme || url.scheme == universalLinkScheme,
              url.host == host
        else {
            throw ParseError.notCompatibleToConfig
        }
    }
    
    func isExternalLink(url: NavigationURL) -> Bool {
        return url.scheme == universalLinkScheme
    }
}
