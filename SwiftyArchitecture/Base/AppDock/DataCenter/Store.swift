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
    
    let accessQueue: DispatchQueue = DispatchQueue(label: Consts.domainPrefix + ".store.access", qos: .userInitiated)
    
    public var db: RealmDataBase
    public var memory: RealmDataBase
    
    public init(appContext: AppContext) {
        self.db = try! RealmDataBase(appContext: appContext, migration: { migration, oldSchemaVersion in
            print("Migrating from \(oldSchemaVersion) to \(RealmDataBase.schemaVersion)")
        })
        self.memory = RealmDataBase.inMemoryDatabase(appContext: appContext)
        self.requestRecords = RequestRecords()
        super.init()
    }
    
    internal var requestRecords: RequestRecords
    
    deinit {
        self.db.realm.invalidate()
        self.memory.realm.invalidate()
    }
    
    // MARK: - QUERY
    public func object<KeyType, Element: Object>(with key: KeyType, type: Element.Type) -> Observable<Element?> {
        return Observable<Element?>.create { observer in
            observer.onNext(self.db.realm.object(ofType: type, forPrimaryKey: key))
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    public func objects<Element: Object>(with type: Element.Type) -> Observable<[Element]> {
        return Observable<[Element]>.create { observer in
            observer.onNext(self.db.realm.objects(type).toArray())
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    public func objects<Element: Object>(with type: Element.Type, predicate: NSPredicate) -> Observable<[Element]> {
        return Observable<[Element]>.create { observer in
            observer.onNext(self.db.realm.objects(type).filter(predicate).toArray())
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    public func objects<Element: Object>(
        with type: Element.Type,
        where query: @escaping (Query<Element>) -> Query<Element>)
    -> Observable<[Element]> {
        return Observable<[Element]>.create { observer in
            observer.onNext(self.db.realm.objects(type).where(query).toArray())
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    // MARK: - WRITE
    
    public func upsert<Element: Object>(object: Element) -> Observable<Void> {
        return .create { ob in
            do {
                let realm = self.db.getRealmOnOtherThread()
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
