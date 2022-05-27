//
//  RealmDataBase.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/10.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit
import RxRealm
import RxSwift
import RealmSwift

public class RealmDataBase: NSObject {
    
    public var realm: Realm
    
    public init(appContext context: AppContext) throws {
        let name = context.userId + "RLM"
        self.realm = try Realm(fileURL: URL(fileURLWithPath: Path.docPath + name))
    }
    
    public init(realm: Realm) {
        self.realm = realm
    }
    
    public static func inMemoryDatabase(appContext context: AppContext) -> RealmDataBase {
        var config = Realm.Configuration.defaultConfiguration;
        config.inMemoryIdentifier = "RLM.MEMORY.\(context.userId)";
        let realm = try! Realm(configuration: config)
        return RealmDataBase(realm: realm)
    }
    
}

extension Realm {
    
    public func safeWrite(_ block: (Realm) throws -> Void) throws -> Void {
        if isInWriteTransaction {
            try block(self)
        } else {
            try self.write({
                try block(self)
            })
        }
    }
}
