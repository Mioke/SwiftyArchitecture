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


public class DataCenter: NSObject {
    
    public var db: RealmDataBase
    
    public init(with db: RealmDataBase) {
        self.db = db
        super.init()
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
