//
//  DatabaseCommand.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/10.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

class DatabaseCommand: NSObject {
    
    class func createTable(table: TableProtocol, inDataBase database: KMPersistanceDatabase) -> Bool {
        
        //  TODO: If the table is already there, do nothing.
        //  Now execute the sql will cause an error of "table existes"
        //  To solve this problem, we can create a default table in every database to record what tables it has.
        
        let params = NSMutableArray()
        
        for key in table.tableColumnInfo.keys {
            params.addObject("\(key) \(table.tableColumnInfo[key]!)")
        }
        
        let sql = "create table if not exists '\(table.tableName)' (\(params.componentsJoinedByString(",")))"
        
        return database.execute(sql, withArgumentsInDictionary: nil)
    }
    
    class func replaceCommandWithTable(table: TableProtocol, record: RecordProtocol) -> String {
        
        guard let params = record.dictionaryRepresentationInTable(table) else {
            assert(false, "DatabaseCommand REPLACE params should not be ampty")
            return ""
        }
        var sql = "replace into \(table.tableName) ("
        
        let content = NSMutableArray()
        let values = NSMutableArray()
        
        for key in params.keys {
            content.addObject("\(key)")
            values.addObject(":\(key)")
        }
        sql += "\(content.componentsJoinedByString(","))) values (\(values.componentsJoinedByString(",")))"
        
        Log.debugPrintln(sql)
        // TODO: Whether is needed to execute the sql here(the function of executing should be owned by Command?)
//        table.database!.execute(sql, withArgumentsInDictionary: <#T##[String : AnyObject]?#>)
        
        return sql
    }
    
    class func queryCommandWithTable(table: TableProtocol, select: String?, condition: DatabaseCommandCondition) -> String {
        
        let selectSql = select == nil ? "*" : "'\(select!)'"
        var sql = "select \(selectSql) from \(table.tableName)"
        condition.applyConditionToCommand(&sql)
        
        return sql
    }
}

// MARK: - Command condition

class DatabaseCommandCondition: NSObject {
    
    var whereConditions: String?
    // TODO: --- whereConditionsParams ---
//    var whereConditionsParams: [String: AnyObject]?
    
    var orderBy: String?
    var isDESC: Bool?
    
    var limit: Int?
    var isDistinct: Bool?
    
    func applyConditionToCommand(inout command: String) {
        
        if self.whereConditions != nil/* && self.whereConditionsParams != nil */{
            command.appendContentsOf(" where \(self.whereConditions!)")
        }
        if self.orderBy != nil {
            command.appendContentsOf(" order by \(self.orderBy!)")
        }
        if self.isDESC != nil {
            command.appendContentsOf(" \(self.isDESC! ? "DESC" : "ASC")")
        }
        if self.limit != nil {
            command.appendContentsOf(" limit \(self.limit!)")
        }
        if let isDistinct = self.isDistinct where isDistinct {
            command.replaceRange(command.startIndex.advancedBy(6) ..< command.startIndex.advancedBy(6), with: " distinct")
        }
    }
}


