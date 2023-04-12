//
//  DataAccessObject.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import Foundation
import RxSwift
import RxRealm
import RealmSwift

public typealias DAO = DataAccessObject

public class DataAccessObject<T: Object> {
    
    private static var store: Store {
        return AppContext.current.store
    }
    
    public static var all: Observable<[T]> {
        return store.objects(with: T.self).map { $0.toArray() }
    }
    
    public static func object<KeyType>(with key: KeyType) -> Observable<T?> {
        return store.object(with: key, type: T.self)
    }
    
    public static func objects(with predicate: NSPredicate) -> Observable<[T]> {
        return store.objects(with: T.self, predicate: predicate).map { $0.toArray() }
    }
    
    public static func objects(with query: @escaping (Query<T>) -> Query<T>) -> Observable<[T]> {
        return store.objects(with: T.self, where: query).map { $0.toArray() }
    }

}


