//
//  NetworkManagerProtocol.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

struct ErrorResultType: ErrorType {
    var description: String
    var code: Int
}

enum ResultType<T> {
    case Success(T)
    case Failed(ErrorResultType)
    
    func isSuccess() -> Bool {
        
        switch self {
        case .Success(_):
            return true
        default:
            return false
        }
    }
    
    func successData() -> T? {
        switch self {
        case .Success(let x):
            return x
        default:
            return nil
        }
    }
    
    func error() -> ErrorResultType? {
        switch self {
        case .Failed(let x):
            return x
        default:
            return nil
        }
    }
}

protocol NetworkManagerProtocol {
    
    typealias returnType
    
    var server: String { get }
    
    func sendRequestWithApiName(apiName: String, param: [String: AnyObject]?, timeout: NSTimeInterval?) throws -> ResultType<returnType>
}
