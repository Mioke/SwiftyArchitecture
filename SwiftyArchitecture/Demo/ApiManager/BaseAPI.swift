//
//  BaseAPI.swift
//  SAD
//
//  Created by KelanJiang on 2023/3/16.
//  Copyright © 2023 KleinMioke. All rights reserved.
//

import Foundation

protocol ApplicationBasedApiInfoProtocol: ApiInfoProtocol { }

extension ApplicationBasedApiInfoProtocol where ResultType: Decodable {
    static var responseSerializer: ResponseSerializer<ResultType> {
        return MIOSwiftyArchitecture.JSONCodableResponseSerializer<ResultType>()
    }
}
