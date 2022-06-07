//
//  Consts.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/6/2.
//

import Foundation

public extension Consts {
    static let componentizeDomain = "com.mioke.swiftyarchitecture.componentize"
}

extension KitErrors {
    static var graphCycleInfo: Info {
        .init(code: .graphCycle, message: "Detacted graph circle.")
    }
    static let graphCycle: Error = error(domain: Consts.componentizeDomain, info: KitErrors.graphCycleInfo)
}
