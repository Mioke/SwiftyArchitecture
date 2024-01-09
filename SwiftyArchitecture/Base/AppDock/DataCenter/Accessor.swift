//
//  Accessor.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import Foundation
import RxSwift
import RxRealm
import RealmSwift

public class Accessor<T: Object> {
    
    public static func context(_ type: Store.ContextType) -> Self {
        return self.init(contextType: type)
    }
    
    let contextType: Store.ContextType
    
    internal required init(contextType: Store.ContextType) {
        self.contextType = contextType
    }
    
    private var store: ObservableDataBase {
        return AppContext.current.store.context(contextType)
    }
    
    public var all: Observable<[T]> {
        return store.objects(with: T.self).map { $0.toArray() }
    }
    
    public func object<KeyType>(with key: KeyType) -> Observable<T?> {
        return store.object(with: key, type: T.self)
    }
    
    public func objects(with predicate: NSPredicate) -> Observable<[T]> {
        return store.objects(with: T.self, predicate: predicate).map { $0.toArray() }
    }
    
    public func objects(with query: @escaping (Query<T>) -> Query<Bool>) -> Observable<[T]> {
        return store.objects(with: T.self, where: query).map { $0.toArray() }
    }

}


