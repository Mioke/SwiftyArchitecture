//
//  KMPersistance.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/1.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import FMDB

protocol PersistanceManagerProtocol: NSObjectProtocol {
    
}

// MARK: - Database

protocol DatabaseManagerProtocol: PersistanceManagerProtocol {
    
    var path: String { get }
    
    var database: FMDatabaseQueue { get }
    var databaseName: String { get }
    
//    static var instance: protocol<DatabaseManagerProtocol> { get set }
}

class KMPersistanceDatabase: NSObject {
    
    private weak var child: protocol<DatabaseManagerProtocol>?
    
    override init() {
        super.init()
        
        if self is protocol<DatabaseManagerProtocol> {
            self.child = self as? protocol<DatabaseManagerProtocol>
            assert(self.child != nil, "KMPersistanceDatabase's database couldn't be nil")
        } else {
            assert(false, "KMPersistanceDatabase's subclass must follow the KMPersistanceProtocol")
        }
    }
    
    deinit {
        self.close()
    }
    
    func close() -> Void {
        self.child!.database.close()    
    }
    
    /**
     Query infomation
     
     - parameter query: query SQL string
     - parameter args:  the args in SQL string
     
     - returns: result array
     */
    func query(query: String, withArgumentsInArray args: [AnyObject]?) -> NSMutableArray {
        return DatabaseManager.database(self.child!.database, query: query, withArgumentsInArray: args)
    }
    
    /**
     Execute operation
     
     - parameter sql:  SQL string
     - parameter args: The args in sql string
     
     - returns: Whether succeed
     */
    func execute(sql: String, withArgumentsInDictionary args: [String: AnyObject]!) -> Bool {
        return DatabaseManager.database(self.child!.database, execute: sql, withArgumentsInDictionary: args)
    }
    
    /**
     Execute operation
     
     - parameter sql:  SQL string
     - parameter args: The args array in sql string
     
     - returns: Succeed or not
     */
    func execute(sql: String, withArgumentsInArray args: [AnyObject]!) -> Bool {
        return DatabaseManager.database(self.child!.database, execute: sql, withArgumentsInArray: args)
    }
    
}

// MARK: - Table

protocol TableProtocol: PersistanceManagerProtocol {
    
    weak var database: KMPersistanceDatabase? { get }
    
    var tableName: String { get }
    
    var tableColumnInfo: [String: String] { get }
}

class KMPersistanceTable: NSObject {
    
    private weak var child: TableProtocol?
    
    override init() {
        super.init()
        if self is TableProtocol {
            self.child = (self as! TableProtocol)
            DatabaseCommand.createTable(self.child!, inDataBase: self.child!.database!)
        } else {
            assert(false, "KMPersistanceTable must conform to TableProtocol")
        }
    }
    
    func replaceRecord(record: RecordProtocol) -> Bool {
        
        guard let params = record.dictionaryRepresentationInTable(self.child!)
            where params.count != 0 else {
            return false
        }
        let sql = DatabaseCommand.replaceCommandWithTable(self.child!, record: record)
        
        return self.child!.database!.execute(sql, withArgumentsInDictionary: params)
    }
    
    func queryRecordWithSelect(select: String?, condition: DatabaseCommandCondition) -> NSMutableArray {
        
        let sql = DatabaseCommand.queryCommandWithTable(self.child!, select: select, condition: condition)
        
        return self.child!.database!.query(sql, withArgumentsInArray: nil)
    }
    
    func deleteRecordWithCondition(condition: DatabaseCommandCondition) -> Bool {
        
        let sql = DatabaseCommand.deleteCommandWithTable(self.child!, condition: condition)
        
        return self.child!.database!.execute(sql, withArgumentsInArray: nil)
    }
}

// MARK: - Record

protocol RecordProtocol: PersistanceManagerProtocol {
    
    func dictionaryRepresentationInTable(table: TableProtocol) -> [String: AnyObject]?
    static func readFromQueryResultDictionary(dictionary: NSDictionary, table: TableProtocol) -> RecordProtocol?
}

// Default implementation, make this func optional-like
extension RecordProtocol {
    
    static func readFromQueryResultDictionary(dictionary: NSDictionary, table: TableProtocol) -> RecordProtocol? {
        return nil
    }
}




















