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

public typealias DAO = DataAccessObject

public class DataAccessObject<T: Object> {
    
    private static var store: Store {
        return AppContext.current.store
    }
    
    public static var all: Observable<[T]> {
        return store.objects(with: T.self)
    }
    
    public static func object<KeyType>(with key: KeyType) -> Observable<T?> {
        return store.object(with: key, type:T.self)
    }
    
    public static func objects(with predicate: NSPredicate) -> Observable<[T]> {
        return store.objects(with: T.self, predicate: predicate)
    }
    
    public static func objects(with query: @escaping (Query<T>) -> Query<T>) -> Observable<[T]> {
        return store.objects(with: T.self, where: query)
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
    
    public static func update(with request: Request<T>) -> ObservableSignal {
        
        if let rst = self.checkFreshness(with: request) {
            return rst
        }
        
        return ObservableSignal.create { observer in
            let api = T.api
            let rlm = self.stored.realm
            return api.rxLoadData(with: request.params)
            // TODO: - update the scheduler
                .subscribe(on: MainScheduler.instance)
                .map {
                    try T.serialize(data: $0) as Object
                }
                .do(onError: { observer.onError($0) })
                .subscribe(rlm.rx.add(update: .modified, onError: { _, error in
                    observer.onError(error)
                }))
        }
    }
    
    private static func checkFreshness(with request: Request<T>) -> ObservableSignal? {
        switch T.requestFreshness {
        case .seconds(_):
            if AppContext.current.store.requestRecords.shouldSend(request: request) {
                return nil
            } else {
                return ObservableSignal.signal
            }
        default:
            return nil
        }
    }
    
    private static var stored: RealmDataBase {
        switch T.cachePolicy {
        case .memoryCache:
            return AppContext.current.store.memory
        case .diskCache:
            return AppContext.current.store.db
        case .persistance:
            return AppContext.current.store.db
        }
    }
    
}

final public class Request<T: DataCenterManaged> : NSObject {
    
    public var params: [String: Any]?
    
}

