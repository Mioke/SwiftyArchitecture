//
//  DataCenter.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit
import RxRealm
import RxSwift
import RealmSwift

/// Rx type API for the Realm database. By default, all the operation is not running on the main thread, if you want to
/// use the objects on the main thread, `freeze()` the objects and call `observe(on:)` to switch to the main thread, and
/// then `thaw()` the objects.
public protocol ObservableDataBase {
    
    func object<KeyType, Element: Object>(with key: KeyType, type: Element.Type) -> Observable<Element?>
    
    func objects<Element: Object>(with type: Element.Type) -> Observable<Results<Element>>
    
    func objects<Element: Object>(with type: Element.Type, predicate: NSPredicate) -> Observable<Results<Element>>
    
    func objects<Element: Object>(
        with type: Element.Type,
        where query: @escaping (Query<Element>) -> Query<Bool>) -> Observable<Results<Element>>
    
    func upsert<Element: Object>(object: Element) -> ObservableSignal
    
    func update(with block: @escaping (Realm) -> Void) -> ObservableSignal
}

/**
 Note: We are not using a abstract layer for data APIs, because now we are strongly depend on
 Realm database, so if there need to switch to other database one day, then consider to
 create a protocol of APIs as an abstract layer.
 
 Currently, I design this for Realm Object, especialy the `live object` and `thread safe` features. It's highly depend
 on the `Realm` database, so it might not flexible enough to migrate database if needed.
*/
public class Store: NSObject {
    
//    let accessQueue: DispatchQueue = DispatchQueue(label: Consts.domainPrefix + ".store.access", qos: .default)
    
    /// A database stored in `<root>/Library/Cache`, for data which want to keep for a while and unnecessary, may get 
    /// deleted by system when disk free capicity is running low.
    internal var cache: RealmDataBase
    
    /// A database only in memory, reset after application process been killed.
    internal var memory: RealmDataBase
    
    /// A database stored in `<root>/Document`, for data which want to keep it until developer deleted it.
    internal var persistance: RealmDataBase
    
    public enum ContextType {
        case persistance, cache, memory
    }
    
    public init(appContext: AppContext) throws {
        
        var baseURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,
                                                  appropriateFor: nil, create: true)
            .appendingPathComponent(Consts.domainPrefix + "/Store")
        try FileManager.default.createDiractoryIfNeeded(at: baseURL)
        
        let cacheURL = baseURL.appendingPathComponent("cache-\(appContext.userId)-RLM")
        self.cache = try RealmDataBase(location: cacheURL,
                                       schemaVersion: appContext.storeVersions.cacheVersion,
                                       migration: { [weak appContext] migration, oldSchemaVersion in
            if let handler = appContext?.storeDelegate {
                handler.realmDataBasePerform(migration: migration, oldSchema: oldSchemaVersion)
            }
        })
        
        baseURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                              appropriateFor: nil, create: true)
            .appendingPathComponent(Consts.domainPrefix + "/Store")
        try FileManager.default.createDiractoryIfNeeded(at: baseURL)
        
        let persistanceURL = baseURL.appendingPathComponent("persistance-\(appContext.userId)-RLM")
        self.persistance = try RealmDataBase(location: persistanceURL,
                                             schemaVersion: appContext.storeVersions.persistanceVersion,
                                             migration: { [weak appContext] migration, oldSchemaVersion in
            if let handler = appContext?.storeDelegate {
                handler.realmDataBasePerform(migration: migration, oldSchema: oldSchemaVersion)
            }
        })
        
        self.memory = RealmDataBase.inMemoryDatabase(appContext: appContext)
        super.init()
    }
    
    public func context(_ type: ContextType) -> ObservableDataBase {
        switch type {
        case .persistance:
            return persistance
        case .cache:
            return cache
        case .memory:
            return memory
        }
    }
    
    deinit {
        self.cache.invalidate()
        self.memory.invalidate()
        self.persistance.invalidate()
    }

}

/// - Important: Because of the Realm database is controlled by MVCC and only can use the Realm instance in the same
/// thread, so the Observable asynchronouse API won't apply any `Scheduler` to the subscribtion or observation logic.
/// You can apply the logics to any `Scheduler` you want, and if you do nothing it will use `CurrentThreadScheduler`.
/// Notice that if you going to switch the results to a new `Scheduler` you should `freeze()` the `Object` before the
/// switching.
extension RealmDataBase : ObservableDataBase {
    
    // MARK: - QUERY
    public func object<KeyType, Element: Object>(with key: KeyType, type: Element.Type) -> Observable<Element?> {
        return Observable<Element?>.throwingCreate { [weak self] observer in
            guard let self else { throw KitErrors.deallocated }
            observer.onNext(try realm.object(ofType: type, forPrimaryKey: key))
            observer.onCompleted()
            return Disposables.create()
        }
        .flatMapLatest { element -> Observable<Element?>in
            guard let ele = element else { return .just(nil) }
            return Observable<Element>.from(object: ele).map { $0 as Element? }
        }
    }
    
    public func objects<Element: Object>(with type: Element.Type) -> Observable<Results<Element>> {
        return .throwingCreate { [weak self] observer in
            guard let self else { throw KitErrors.deallocated }
            observer.onNext(try realm.objects(type))
            return Disposables.create()
        }
        .flatMapLatest { results -> Observable<Results<Element>> in
            return .collection(from: results)
        }
    }
    
    public func objects<Element: Object>(with type: Element.Type,
                                         predicate: NSPredicate)
    -> Observable<Results<Element>> {
        return .throwingCreate { [weak self] observer in
            guard let self else { throw KitErrors.deallocated }
            observer.onNext(try realm.objects(type).filter(predicate))
            return Disposables.create()
        }
        .flatMapLatest { results -> Observable<Results<Element>> in
            return .collection(from: results)
        }
    }
    
    public func objects<Element: Object>(with type: Element.Type,
                                         where query: @escaping (Query<Element>) -> Query<Bool>)
    -> Observable<Results<Element>> {
        return .throwingCreate { [weak self] observer in
            guard let self else { throw KitErrors.deallocated }
            observer.onNext(try realm.objects(type).where(query))
            return Disposables.create()
        }
        .flatMapLatest { results -> Observable<Results<Element>> in
            return .collection(from: results)
        }
    }
    
    // MARK: - WRITE
    
    public func upsert<Element: Object>(object: Element) -> ObservableSignal {
        return update { realm in
            realm.add(object, update: .modified)
        }
    }
    
    public func update(with block: @escaping (Realm) -> Void) -> ObservableSignal {
        return .throwingCreate { [weak self] ob in
            guard let self else { throw KitErrors.deallocated }
            do {
                try realm.safeWrite { realm in
                    block(realm)
                }
            } catch {
                ob.onError(error)
            }
            ob.onNext(())
            ob.onCompleted()
            return Disposables.create()
        }
    }
}


extension Observable {
    
    /// Convinience function for transmit Realm fetch results from a thread to a new one.
    /// - Parameter queue: The destination queue, but actually the `Queue` and `Thread` is not equal, but this is safe.
    /// - Returns: Transmited signal.
    public func transmitRealmResults<T>(to queue: DispatchQueue) -> Observable<Array<T>> where Element == Results<T>, T: Object {
        return map { results -> [T] in
            return results.map { $0.freeze() }
        }
        .observe(on: SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: ""))
        .map { results in
            results.compactMap { $0.thaw() }
        }
    }
    
    
    ///  Convinience function for transmit Realm fetch results from a thread to the main thread.
    /// - Returns: Transmited signal.
    public func trasmitRealmResultsToMainThread<T>() -> Observable<Array<T>> where Element == Results<T>, T: Object {
        return map { results -> [T] in
            return results.map { $0.freeze() }
        }
        .observe(on: MainScheduler.instance)
        .map { results in
            results.compactMap { $0.thaw() }
        }
    }
}


