//
//  RequestRecords.swift
//  MIOSwiftyArchitecture
//
//  Created by Mioke Klein on 2021/5/7.
//

import UIKit

struct RequestRecordNode {
    let requestTime: CFAbsoluteTime
    let freshness: RequestFreshness
    
    var expirationDate: CFAbsoluteTime {
        guard case .seconds(let seconds) = freshness else {
            return 0
        }
        return requestTime + CFAbsoluteTime(seconds)
    }
}

internal class RequestRecords: NSObject {
    
    @ThreadSafe
    var map: [String: RequestRecordNode] = [:]
    
    func key<T: DataCenterManaged>(ofType t: Request<T>) -> String {
        var key = String(describing: type(of: t.self))
        if let params = t.params,
           let data = try? JSONSerialization.data(withJSONObject: params, options: []) {
            key += ".\(data.hashValue)"
        }
        return key
    }
    
    func last<T: DataCenterManaged>(ofRequest request: Request<T>) -> (key: String, node: RequestRecordNode)? {
        let key = self.key(ofType: request)
        if let node = map[key] {
            return (key, node)
        }
        return nil
    }
    
    func update<T: DataCenterManaged>(request: Request<T>) -> Void {
        let freshness = T.requestFreshness
        if case .none = freshness {
            return
        }
        let time = CFAbsoluteTimeGetCurrent()
        map[key(ofType: request)] = RequestRecordNode(requestTime: time, freshness: freshness)
    }
    
    func shouldSend<T: DataCenterManaged>(request: Request<T>) -> Bool {
        guard let info = self.last(ofRequest: request) else {
            return true
        }
        let should = info.node.expirationDate < CFAbsoluteTimeGetCurrent()
        if should {
            map[info.key] = nil
        }
        return should
    }
}
