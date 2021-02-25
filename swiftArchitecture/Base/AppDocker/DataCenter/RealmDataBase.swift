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
    
    public init(with context: AppContext) throws {
        let name = context.currentUserId + "RLM"
        self.realm = try Realm(fileURL: URL(fileURLWithPath: Path.docPath + name))
    }
    
}

extension Realm {
    
    public func safeWrite(block: () throws -> Void) throws -> Void {
        if isInWriteTransaction {
            try block()
        } else {
            try self.write(block)
        }
    }
}
