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

public typealias RealmMigrationBlock = RealmSwift.MigrationBlock

public final class RealmDataBase: NSObject {
    
    public enum `Type` {
        case file
        case memory
    }
    
    public static let schemaVersion: UInt64 = 1
    
    /// This instance is created on main thread, so only write on main thread is allowed. If the code is not sure which
    /// thread would the code running, you can use `getRealmOnOtherThread()` to get a new instance on current thread.
    public var realm: Realm
    public private(set) var type: RealmDataBase.`Type` = .file
    
    private var fileURL: URL?
    private var inMemoryIdentifier: String?
    
    /// Create a file type database using an app context's information.
    /// - Parameters:
    ///   - context: The app context contains user information.
    ///   - migration: The customize migration handler.
    public init(appContext context: AppContext, migration: @escaping RealmMigrationBlock) throws {
        fileURL = URL(fileURLWithPath: Path.docPath).appendingPathComponent(context.userId + "_RLM")
        let config = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: RealmDataBase.schemaVersion,
            migrationBlock: migration,
            deleteRealmIfMigrationNeeded: true
        )
        self.realm = try Realm(configuration: config)
    }
    
    init(realm: Realm) {
        self.realm = realm
    }
    
    public static func inMemoryDatabase(appContext context: AppContext) -> RealmDataBase {
        var config = Realm.Configuration.defaultConfiguration;
        config.inMemoryIdentifier = "RLM.MEMORY.\(context.userId)";
        let realm = try! Realm(configuration: config)
        let db = RealmDataBase(realm: realm)
        db.type = .memory
        db.inMemoryIdentifier = "RLM.MEMORY.\(context.userId)"
        return db
    }
    
    public func getRealmOnOtherThread() -> Realm {
        switch self.type {
        case .file:
            let config = Realm.Configuration(
                fileURL: fileURL,
                schemaVersion: RealmDataBase.schemaVersion,
                deleteRealmIfMigrationNeeded: true
            )
            return try! Realm(configuration: config)
        case .memory:
            var config = Realm.Configuration.defaultConfiguration;
            config.inMemoryIdentifier = self.inMemoryIdentifier;
            return try! Realm(configuration: config)
        }
    }
}

extension Realm {
    
    public func safeWrite(_ block: (Realm) throws -> Void) throws -> Void {
        if isInWriteTransaction {
            try block(self)
        } else {
            try self.write { try block(self) }
        }
    }
}
