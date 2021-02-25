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

public class DataAccessObject<T: Object> : NSObject {
    
    private static var dataCenter: DataCenter {
        return AppContext.current.dataCenter
    }
    
    public static var all: Observable<[T]> {
        return dataCenter.objects(with: T.self)
    }
    
    public static func object<KeyType>(with key: KeyType) -> Observable<T>? {
        return dataCenter.object(with: key, type:T.self)
    }
    
    public static func objects(with predicate: NSPredicate) -> Observable<[T]>? {
        return dataCenter.objects(with: T.self, predicate: predicate)
    }

}

