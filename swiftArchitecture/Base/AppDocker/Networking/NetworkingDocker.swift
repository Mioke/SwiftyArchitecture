//
//  NetworkingDocker.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/9.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit

public protocol Requestable {
    
    func request(with params: [String: Any],
                 completion: @escaping (Swift.Result<Any, Error>) -> Void) -> Void
    
    func upload(with params: [String: Any],
                completion: @escaping (Swift.Result<Any, Error>) -> Void) -> Void
    
    func download(with params: [String: Any],
                  completion: @escaping (Swift.Result<Any, Error>) -> Void) -> Void
}

class NetworkingDocker: NSObject {

    var impl: Requestable
    
    required init(with implement: Requestable) {
        self.impl = implement
        super.init()
    }
    
    func request(with params: [String: Any],
                 completion: @escaping (Swift.Result<Any, Error>) -> Void) -> Void {
        self.impl.request(with: params, completion: completion)
    }
}

// example
extension API: Requestable {
    
    public func upload(with params: [String : Any], completion: (Result<Any, Error>) -> Void) {
        
    }
    
    public func download(with params: [String : Any], completion: (Result<Any, Error>) -> Void) {
        
    }
    
    
    public func request(with params: [String : Any],
                        completion: @escaping (Result<Any, Error>) -> Void) {
        
        self.loadData(with: params).response { (api, data, error) in
            let result: Result<Any, Error>
            
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(data ?? [String: Any]())
            }
            completion(result)
        }
    }
}
