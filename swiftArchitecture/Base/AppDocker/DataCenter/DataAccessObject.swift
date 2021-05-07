//
//  DataAccessObject.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit
import RxSwift
import RxRealm
import RealmSwift

public class DataAccessObject<T: Object> : NSObject {
    
    private static var dataCenter: DataCenter {
        return AppContext.current.dataCenter
    }
    
    public static var all: Observable<[T]> {
        return dataCenter.objects(with: T.self)
    }
    
    public static func object<KeyType>(with key: KeyType) -> Observable<T>? {
        return dataCenter.object(with: key, type:T.self)
    }
    
    public static func objects(with predicate: NSPredicate) -> Observable<[T]>? {
        return dataCenter.objects(with: T.self, predicate: predicate)
    }

}

//public enum CachePolicy: Int {
//    case none
//    case memory
//    case disk
//}

public enum RequestFreshness {
    case none
    case seconds(Int)
}

public protocol DataCenterManaged {
    
    associatedtype DatabaseObjectType
    
    static var api: API { get }
     
//    static var cachePolicy: CachePolicy { get }
    
    static var requestFreshness: RequestFreshness { get }
    
    static func serialize(data: [String: Any]) throws -> DatabaseObjectType
}

// For default values
extension DataCenterManaged {
    
//    static public var cachePolicy: CachePolicy {
//        return .none
//    }
    
    static public var requestFreshness: RequestFreshness {
        return .none
    }
}

extension DataAccessObject where T: DataCenterManaged {
    
    public static func update(with request: Request<T>) -> Observable<Void> {
        
        if let rst = self.checkFreshness(with: request) {
            return rst
        }
        
        return Observable<Void>.create { observer in
            let api = T.api
            let rlm = AppContext.current.dataCenter.db.realm
            return api.rx.loadData(with: request.params)
                .map({ rst in
                    return try T.serialize(data: rst) as! Object
                })
                .subscribe(rlm.rx.add(update: .modified, onError: { _, error in
                    observer.onError(error)
                }))
        }
    }
    
    private static func checkFreshness(with request: Request<T>) -> Observable<Void>? {
        switch T.requestFreshness {
        case .seconds(_):
            if AppContext.current.dataCenter.requestRecords.shouldSend(request: request) {
                return nil
            } else {
                return Observable<Void>.just(())
            }
        default:
            return nil
        }
    }
    
}

final public class Request<T: Object> : NSObject {
    
    public var params: [String: Any]?
    
}

