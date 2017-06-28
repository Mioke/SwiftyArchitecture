//
//  KMPersistance.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/1.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import FMDB

/// Base protocol of presistance
public protocol PersistanceManagerProtocol: NSObjectProtocol {
    
}

// MARK: - Database

/// Database managerment protocol
public protocol DatabaseManagerProtocol: PersistanceManagerProtocol {
    
    /// Path of database
    var path: String { get }
    
    /// The datebase instance
    var database: FMDatabaseQueue { get }
    
    /// The name of database
    var databaseName: String { get }
    
//    static var instance: protocol<DatabaseManagerProtocol> { get set }
}

/// Base database manager.
/// - attention: Don't use this class directly, subclass it.
open class KMPersistanceDatabase: NSObject {
    
    fileprivate weak var child: (DatabaseManagerProtocol)!
    
    public override init() {
        super.init()
        
        if self is DatabaseManagerProtocol {
            self.child = self as! DatabaseManagerProtocol
            assert(self.child != nil, "KMPersistanceDatabase's database couldn't be nil")
        } else {
            assert(false, "KMPersistanceDatabase's subclass must follow the KMPersistanceProtocol")
        }
    }
    
    deinit {
        self.close()
    }
    
    /// Close the database
    public func close() -> Void {
        self.child.database.close()
    }
    
    /**
     Query infomation
     
     - parameter query: query SQL string
     - parameter args:  the args in SQL string
     
     - returns: result array
     */
    public func query(_ query: String, withArgumentsInArray args: [Any]?) -> Array<[AnyHashable: Any]> {
        return DatabaseManager.database(self.child.database, query: query, withArgumentsInArray: args)
    }
    
    /**
     Execute operation
     
     - parameter sql:  SQL string
     - parameter args: The args in sql string
     
     - returns: Whether succeed
     */
    @discardableResult
    public func execute(_ sql: String, withArgumentsInDictionary args: [String: Any]!) -> Bool {
        return DatabaseManager.database(self.child.database, execute: sql, withArgumentsInDictionary: args)
    }
    
    /**
     Execute operation
     
     - parameter sql:  SQL string
     - parameter args: The args array in sql string
     
     - returns: Succeed or not
     */
    @discardableResult
    public func execute(_ sql: String, withArgumentsInArray args: [Any]!) -> Bool {
        return DatabaseManager.database(self.child.database, execute: sql, withArgumentsInArray: args)
    }
    
}

// MARK: - Table

/// Information protocol of a table in database
public protocol TableProtocol: PersistanceManagerProtocol {
    
    /// Database which table is in
    var database: KMPersistanceDatabase { get }
    
    /// table's name
    var tableName: String { get }
    
    /// column informatin of this table, for building table.
    var tableColumnInfo: [String: String] { get }
}

/// Base table manager class
/// - attention: Don't use this classs directly, subclass it.
open class KMPersistanceTable: NSObject {
    
    fileprivate weak var child: TableProtocol!
    
    public override init() {
        super.init()
        if self is TableProtocol {
            self.child = (self as! TableProtocol)
            let _ = DatabaseCommand.createTable(with: self.child, inDatabase: self.child!.database)
        } else {
            assert(false, "KMPersistanceTable must conform to TableProtocol")
        }
    }
    
    /// Excecute `replace` method. Add or replace the record in database.
    ///
    /// - Parameter record: Record to add or replace.
    /// - Returns: Result of execution
    @discardableResult
    public func replace(_ record: RecordProtocol) -> Bool {
        
        guard let params = record.dictionaryRepresentation(in: self.child), params.count != 0 else {
            return false
        }
        let sql = DatabaseCommand.replaceCommand(with: self.child, record: record)
        
        return self.child.database.execute(sql, withArgumentsInDictionary: params)
    }
    
    /// Query records with condition.
    ///
    /// - Parameters:
    ///   - select: Select condition.
    ///   - condition: Other database command condition.
    /// - Returns: An array of result dictionary
    public func queryRecord(with select: String?, condition: DatabaseCommandCondition) -> Array<[AnyHashable: Any]> {
        
        let sql = DatabaseCommand.queryCommand(with: self.child, select: select, condition: condition)
        
        return self.child.database.query(sql, withArgumentsInArray: nil)
    }
    
    /// Delete record.
    ///
    /// - Parameter condition: Database command condition
    /// - Returns: Execution result
    @discardableResult
    public func deleteRecord(with condition: DatabaseCommandCondition) -> Bool {
        
        let sql = DatabaseCommand.deleteCommand(with: self.child, condition: condition)
        
        return self.child.database.execute(sql, withArgumentsInArray: nil)
    }
}

// MARK: - Record

/// Record protocol for models stored in database
public protocol RecordProtocol: PersistanceManagerProtocol {
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

    public static func generate(withDictionary dictionary: [AnyHashable: Any], fromTable table: TableProtocol) -> Self? {
        return nil
    }
    
}


