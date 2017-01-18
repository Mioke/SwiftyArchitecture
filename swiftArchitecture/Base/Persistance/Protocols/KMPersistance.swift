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
    
    fileprivate weak var child: (DatabaseManagerProtocol)?
    
    override init() {
        super.init()
        
        if self is DatabaseManagerProtocol {
            self.child = self as? DatabaseManagerProtocol
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
    func query(_ query: String, withArgumentsInArray args: [Any]?) -> Array<[AnyHashable: Any]> {
        return DatabaseManager.database(self.child!.database, query: query, withArgumentsInArray: args)
    }
    
    /**
     Execute operation
     
     - parameter sql:  SQL string
     - parameter args: The args in sql string
     
     - returns: Whether succeed
     */
    func execute(_ sql: String, withArgumentsInDictionary args: [String: Any]!) -> Bool {
        return DatabaseManager.database(self.child!.database, execute: sql, withArgumentsInDictionary: args)
    }
    
    /**
     Execute operation
     
     - parameter sql:  SQL string
     - parameter args: The args array in sql string
     
     - returns: Succeed or not
     */
    func execute(_ sql: String, withArgumentsInArray args: [Any]!) -> Bool {
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
    
    fileprivate weak var child: TableProtocol?
    
    override init() {
        super.init()
        if self is TableProtocol {
            self.child = (self as! TableProtocol)
            let _ = DatabaseCommand.createTable(with: self.child!, inDatabase: self.child!.database!)
        } else {
            assert(false, "KMPersistanceTable must conform to TableProtocol")
        }
    }
    
    func replace(_ record: RecordProtocol) -> Bool {
        
        guard let params = record.dictionaryRepresentation(in: self.child!), params.count != 0 else {
            return false
        }
        let sql = DatabaseCommand.replaceCommand(with: self.child!, record: record)
        
        return self.child!.database!.execute(sql, withArgumentsInDictionary: params)
    }
    
    func queryRecord(with select: String?, condition: DatabaseCommandCondition) -> Array<[AnyHashable: Any]> {
        
        let sql = DatabaseCommand.queryCommand(with: self.child!, select: select, condition: condition)
        
        return self.child!.database!.query(sql, withArgumentsInArray: nil)
    }
    
    func deleteRecord(with condition: DatabaseCommandCondition) -> Bool {
        
        let sql = DatabaseCommand.deleteCommand(with: self.child!, condition: condition)
        
        return self.child!.database!.execute(sql, withArgumentsInArray: nil)
    }
}

// MARK: - Record

protocol RecordProtocol: PersistanceManagerProtocol {
    /// For mapping between the column in table and the ivar of record class.
    ///
    /// - Parameter table: Which table that represent the maps
    /// - Returns: Map
    func dictionaryRepresentation(in table: TableProtocol) -> [String: Any]?
    /// Todo: For reading records from table and return in model directly.
    ///
    /// - Parameters:
    ///   - dictionary: dictionary description
    ///   - table: table description
    /// - Returns: return value description
    static func generate(withDictionary dictionary: [AnyHashable: Any], fromTable table: TableProtocol) -> Self?
}

// Default implementation, make this func optional-like
extension RecordProtocol {

    static func generate(withDictionary dictionary: [AnyHashable: Any], fromTable table: TableProtocol) -> Self? {
        return nil
    }
    
}


