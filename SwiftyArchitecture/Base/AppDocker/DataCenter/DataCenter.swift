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

// Note: We are not using a abstract layer for data APIs, because now we are strongly dependent on
//       Realm database, so if there need to switch to other database one day, then consider to
//       create a protocol of APIs as an abstract layer.
public class DataCenter: NSObject {
    
    public var db: RealmDataBase
    public var memory: RealmDataBase
    
    public init(appContext: AppContext) {
        self.db = try! RealmDataBase(appContext: appContext)
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
    
    public func object<KeyType, Element: Object>(with key: KeyType, type: Element.Type) -> Observable<Element>? {
        if let obj = self.db.realm.object(ofType: type, forPrimaryKey: key) {
            return Observable.from(object: obj)
        }
        return nil
    }
    
    public func objects<Element: Object>(with type: Element.Type) -> Observable<[Element]> {
        let result = self.db.realm.objects(type)
        return Observable.array(from: result)
    }
    
    public func objects<Element: Object>(with type: Element.Type, predicate: NSPredicate) -> Observable<[Element]> {
        let result = self.db.realm.objects(type).filter(predicate)
        return Observable.array(from: result)
    }
    
    public func objects<Element: Object>(with type: Element.Type, isIncluded: (Element) -> Bool) -> Observable<[Element]> {
        let result = self.db.realm.objects(type).filter(isIncluded)
        return Observable.from(optional: result)
    }
    
    // MARK: - WRITE

}
