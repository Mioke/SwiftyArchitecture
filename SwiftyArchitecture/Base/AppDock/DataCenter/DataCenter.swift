//
//  DataCenter.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2023/4/10.
//

import Foundation
import RxSwift
import RxRealm
import RealmSwift

/** Wrapper of logics dealing from request to store.
 
 Design:
 ```
 ┌───────────────┐                               ┌───────────────┐
 │    Request    │                               │   Realm DB    │
 └───────┬───────┘                               └───────▲───────┘
         │                                               │
         │                  ┌───────────────┐            │
         │             ┌──◄►│ Biz/DB Model1 ├────────────┤
 ┌───────▼───────┐     │    └───────────────┘            │
 │   API Model   ├─────┤                                 │
 └───────────────┘     │    ┌───────────────┐            │
                       └──◄►│ Biz/DB Model2 ├────────────┘
                            └───────────────┘
 ```
 */
public class DataCenter {
    
    static let workingQueue: SerialDispatchQueueScheduler =
        .init(qos: .default, internalSerialQueueName: Consts.domainPrefix + ".data-center-working")
    
    internal static let shared: DataCenter = .init()
    internal var requestRecords: RequestRecords = .init()
    
    public static func update<T: DataCenterManaged>(with request: Request<T>) -> ObservableSignal {
        
        if let rst = shared.checkFreshness(with: request) {
            return rst
        }
        
        return ObservableSignal.create { observer in
            let api = T.api
            return api.rxSendRequest(with: request.params)
                .observe(on: workingQueue)
                .map { result -> [Object] in
                    return try T.serialize(data: result)
                }
                .do(onError: { observer.onError($0) })
                .subscribe(onNext: { objects in
                    do {
                        try self.store(of: T.self).currentThreadInstance.safeWrite { rlm in
                            rlm.add(objects, update: .modified)
                        }
                        observer.signal(); observer.onCompleted()
                    } catch {
                        observer.onError(error)
                    }
                })
        }
    }
    
    private func checkFreshness<T: DataCenterManaged>(with request: Request<T>) -> ObservableSignal? {
        switch T.requestFreshness {
        case .seconds(_):
            if requestRecords.shouldSend(request: request) {
                return nil
            } else {
                return ObservableSignal.signal
            }
        default:
            return nil
        }
    }
    
    private static func store<T: DataCenterManaged>(of type: T.Type) -> RealmDataBase {
        switch T.cachePolicy {
        case .memoryCache:
            return AppContext.current.store.memory
        case .diskCache:
            return AppContext.current.store.cache
        case .persistance:
            return AppContext.current.store.persistance
        }
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
    static func serialize(data: APIInfo.ResultType) throws -> [Object]
}

// For default values
extension DataCenterManaged {
    
    static public var cachePolicy: StorePolicy {
        return .diskCache
    }
    
    static public var requestFreshness: RequestFreshness {
        return .none
    }
    
    static public var api: API<APIInfo> {
        return API<APIInfo>()
    }
}

public struct Request<T: DataCenterManaged> {
    
    public var params: T.APIInfo.RequestParam?
    
    public init(params: T.APIInfo.RequestParam? = nil) {
        self.params = params
    }
    
}
