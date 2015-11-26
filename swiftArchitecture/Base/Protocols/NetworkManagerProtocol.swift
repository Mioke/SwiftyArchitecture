//
//  NetworkManagerProtocol.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

struct ErrorResultType {
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
    
    func sendRequestOfURLString(urlString: String, param: [String: AnyObject]?, timeout: NSTimeInterval?) -> ResultType<returnType>
}
