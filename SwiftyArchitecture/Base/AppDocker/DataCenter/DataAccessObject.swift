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

typealias DAO = DataAccessObject

public class DataAccessObject<T: Object> : NSObject {
    
    private static var dataCenter: DataCenter {
        return AppContext.current.dataCenter
    }
    
    public static var all: Observable<[T]> {
        return dataCenter.objects(with: T.self)
    }
    
    public static func object<KeyType>(with key: KeyType) -> Observable<T?> {
        return dataCenter.object(with: key, type:T.self)
    }
    
    public static func objects(with predicate: NSPredicate) -> Observable<[T]>? {
        return dataCenter.objects(with: T.self, predicate: predicate)
    }

}

public enum StorePolicy: Int {
    case memoryCache
    case diskCache
    case persistance
}

public enum RequestFreshness {
    case none
    case seconds(Int)
}

/// Let data center handle your data, automaticaly request and save.
public protocol DataCenterManaged {
    
    // The Object type in database
    associatedtype DatabaseObject: Object
    
    // API information class for requesting data.
    associatedtype APIInfo: ApiInfoProtocol
    
    /// API instance
    static var api: API<APIInfo> { get }
    
    /// set your data's cache policy
    static var cachePolicy: StorePolicy { get }
    
    /// Refreshness for request
    static var requestFreshness: RequestFreshness { get }
    
    /// Serializing function for converting API's result to database Object.
    /// - Parameter data: Api's result.
    static func serialize(data: APIInfo.ResultType) throws -> DatabaseObject
}

// For default values
extension DataCenterManaged {
    
    static public var cachePolicy: StorePolicy {
        return .memoryCache
    }
    
    static public var requestFreshness: RequestFreshness {
        return .none
    }
    
    static public var api: API<APIInfo> {
        return API<APIInfo>()
    }
}

extension DataAccessObject where T: DataCenterManaged {
    
    public static func update(with request: Request<T>) -> Observable<Void> {
        
        if let rst = self.checkFreshness(with: request) {
            return rst
        }
        
        return Observable<Void>.create { observer in
            let api = T.api
            let rlm = self.stored.realm
            return api.rx.loadData(with: request.params)
                .map({ rst in
                    return try T.serialize(data: rst) as Object
                })
                .do(onError: { observer.onError($0) })
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
    
    private static var stored: RealmDataBase {
        switch T.cachePolicy {
        case .memoryCache:
            return AppContext.current.dataCenter.memory
        case .diskCache:
            return AppContext.current.dataCenter.db
        case .persistance:
            return AppContext.current.dataCenter.db
        }
    }
    
}

final public class Request<T: Object> : NSObject {
    
    public var params: [String: Any]?
    
}

