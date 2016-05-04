//
//  NetworkManagerProtocol.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

class ErrorResultType: NSObject, ErrorType {
    var desc: String = "Undefined error"
    var code: Int = 0
    
    convenience init(desc: String, code: Int) {
        self.init()
        
        self.desc = desc
        self.code = code
    }
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
    
    associatedtype returnType
    
    var server: String { get }
    
    func sendRequestWithApiName(apiName: String, param: [String: AnyObject]?, timeout: NSTimeInterval?) throws -> ResultType<returnType>
}
