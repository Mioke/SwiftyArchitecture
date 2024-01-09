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
    
    private var realmConfiguration: Realm.Configuration
    
    /// The read-write context of Realm.
    public var realm: Realm {
        get throws { return try currentThreadInstance }
    }
    // TODO: - Add read-only context and syncing context logic.
    // public var readOnly: Realm
    
    public private(set) var type: RealmDataBase.`Type` = .file
    
    internal var internalQueue: DispatchQueue = .init(label: Consts.domainPrefix + ".RDB.internal", qos: .default)
    internal lazy var internalScheduler: SchedulerType = SerialDispatchQueueScheduler(
        queue: internalQueue,
        internalSerialQueueName: Consts.domainPrefix + ".RDB.internal")
    
    /// Create a file type database using an app context's information.
    /// - Parameters:
    ///   - context: The app context contains user information.
    ///   - migration: The customize migration handler.
    public init(location: URL, schemaVersion: UInt64, migration: @escaping RealmMigrationBlock) throws {
        self.realmConfiguration = Realm.Configuration(
            fileURL: location,
            schemaVersion: schemaVersion,
            migrationBlock: migration,
            deleteRealmIfMigrationNeeded: true
        )
    }
    
    init(realmConfiguration: Realm.Configuration) {
        self.realmConfiguration = realmConfiguration
        super.init()
    }
    
    public static func inMemoryDatabase(appContext context: AppContext) -> RealmDataBase {
        var config = Realm.Configuration.defaultConfiguration;
        config.inMemoryIdentifier = "RLM.MEMORY.\(context.userId)";
        let db = RealmDataBase(realmConfiguration: config)
        db.type = .memory
        return db
    }
    
    public var currentThreadInstance: Realm  {
        get throws {
            return try Realm(configuration: realmConfiguration)
        }
    }
    
    public func invalidate() {
        try? realm.invalidate()
    }
}

extension Realm {
    
    public func safeWrite(_ block: (Realm) throws -> Void) throws -> Void {
        if isInWriteTransaction {
            try block(self)
            try commitWrite()
        } else {
            try self.write { try block(self) }
        }
    }
}
