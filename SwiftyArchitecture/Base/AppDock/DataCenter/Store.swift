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

/**
 Note: We are not using a abstract layer for data APIs, because now we are strongly depend on
 Realm database, so if there need to switch to other database one day, then consider to
 create a protocol of APIs as an abstract layer.
 
 Currently, I design this for Realm Object, especialy the `live object` and `thread safe` features. It's highly depend
 on the `Realm` database, so it might not flexible enough to migrate database if needed.
*/
public class Store: NSObject {
    
//    let accessQueue: DispatchQueue = DispatchQueue(label: Consts.domainPrefix + ".store.access", qos: .default)
    
    /// A database stored in `<root>/Library/Cache`, for data which want to keep for a while and unnecessary, may get deleted by system when disk free capicity is running low.
    public internal(set) var cache: RealmDataBase
    
    /// A database only in memory, reset after application process been killed.
    public internal(set) var memory: RealmDataBase
    
    /// A database stored in `<root>/Document`, for data which want to keep it until developer deleted it.
    public internal(set) var persistance: RealmDataBase
    
    public init(appContext: AppContext) throws {
        
        var baseURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
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
        
        baseURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
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
    
    deinit {
        self.cache.realm.invalidate()
        self.memory.realm.invalidate()
        self.persistance.realm.invalidate()
    }
    
    // MARK: - QUERY
    public func object<KeyType, Element: Object>(with key: KeyType, type: Element.Type) -> Observable<Element?> {
        return Observable<Element?>.create { observer in
            observer.onNext(self.cache.realm.object(ofType: type, forPrimaryKey: key))
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    public func objects<Element: Object>(with type: Element.Type) -> Observable<Results<Element>> {
        return Observable<Results<Element>>
            .collection(from: cache.realm.objects(type))
    }
    
    public func objects<Element: Object>(with type: Element.Type, predicate: NSPredicate) -> Observable<Results<Element>> {
        return Observable<Results<Element>>
            .collection(from: cache.realm.objects(type).filter(predicate))
    }
    
    public func objects<Element: Object>(
        with type: Element.Type,
        where query: @escaping (Query<Element>) -> Query<Element>)
    -> Observable<Results<Element>> {
        return Observable<Results<Element>>
            .collection(from: cache.realm.objects(type).where(query))
    }
    
    // MARK: - WRITE
    
    public func upsert<Element: Object>(object: Element) -> ObservableSignal {
        return .create { ob in
            do {
                let realm = try self.cache.currentThreadInstance
                try realm.safeWrite { realm in
                    realm.add(object, update: .modified)
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
