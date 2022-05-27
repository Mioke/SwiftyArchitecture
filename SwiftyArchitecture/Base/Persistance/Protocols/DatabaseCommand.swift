//
//  DatabaseCommand.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/10.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

/// Database command generator.
public class DatabaseCommand: NSObject {
    
    @discardableResult
    public class func createTable(with table: TableProtocol, inDatabase database: KMPersistanceDatabase) -> Bool {
        
        //  TODO: If the table is already there, do nothing.
        //  Now execute the sql will cause an error of "table existes"
        //  To solve this problem, we can create a default table in every database to record what tables it has.
        
        let params = NSMutableArray()
        
        for key in table.tableColumnInfo.keys {
            params.add("'\(key)' \(table.tableColumnInfo[key]!)")
        }
        
        let sql = "create table if not exists '\(table.tableName)' (\(params.componentsJoined(by: ",")))"
        
        return database.execute(sql, withArgumentsInDictionary: nil)
    }
    
    public class func replaceCommand(with table: TableProtocol, record: RecordProtocol) -> String {
        
        guard let params = record.dictionaryRepresentation(in: table) else {
            assert(false, "DatabaseCommand REPLACE params should not be ampty")
            return ""
        }
        var sql = "replace into \(table.tableName) ("
        
        let content = NSMutableArray()
        let values = NSMutableArray()
        
        for key in params.keys {
            content.add("'\(key)'")
            values.add(":\(key)")
        }
        sql += "\(content.componentsJoined(by: ","))) values (\(values.componentsJoined(by: ",")))"
        
        print(sql)
        
        return sql
    }
    
    public class func queryCommand(with table: TableProtocol, select: String?, condition: DatabaseCommandCondition) -> String {
        
        let selectSql = select == nil ? "*" : "'\(select!)'"
        var sql = "select \(selectSql) from \(table.tableName)"
        condition.applyCondition(to: &sql)
        
        return sql
    }
    
    public class func deleteCommand(with table: TableProtocol, condition: DatabaseCommandCondition) -> String {
        
        var sql = "delete from \(table.tableName)"
        condition.applyCondition(to: &sql)
        
        return sql
    }
}

// MARK: - Command condition

/// Database command condition object.
public class DatabaseCommandCondition: NSObject {
    
    /// Where condition, like: `"uid=812, age>12"`
    public var whereConditions: String?
    // TODO: --- whereConditionsParams ---
//    var whereConditionsParams: [String: AnyObject]?
    
    /// For ordering result.
    public var orderBy: String?
    
    /// DESC or ASC
    public var isDESC: Bool?
    
    /// For limiting result
    public var limit: Int?
    
    /// For distinct result
    public var isDistinct: Bool?
    
    public func applyCondition(to command: inout String) {
        
        if self.whereConditions != nil/* && self.whereConditionsParams != nil */{
            command.append(" where \(self.whereConditions!)")
        }
        if self.orderBy != nil {
            command.append(" order by \(self.orderBy!)")
        }
        if self.isDESC != nil {
            command.append(" \(self.isDESC! ? "DESC" : "ASC")")
        }
        if self.limit != nil {
            command.append(" limit \(self.limit!)")
        }
        if let isDistinct = self.isDistinct, isDistinct {
            command.replaceSubrange(command.index(command.startIndex, offsetBy: 6) ..< command.index(command.startIndex, offsetBy: 6), with: " distinct")
        }
    }
}


