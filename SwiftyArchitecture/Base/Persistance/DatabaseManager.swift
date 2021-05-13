//
//  DatabaseManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/1.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import FMDB

/// Real database command executor
final public class DatabaseManager: NSObject {
    
    /// Query function
    public class func database(_ databaseQueue: FMDatabaseQueue, query: String, withArgumentsInArray args: [Any]?) -> Array<[AnyHashable: Any]> {
        
        var rstArray = Array<[AnyHashable: Any]>()
        
        databaseQueue.inTransaction { (db: FMDatabase?, roolback: UnsafeMutablePointer<ObjCBool>?) in
            guard let db = db else {
                return
            }
            if let rst = db.executeQuery(query, withArgumentsIn: args ?? []) {
                while rst.next() {
                    if let dic = rst.resultDictionary {
                        rstArray.append(dic)
                    }
                }
                rst.close()
            }
        }
        return rstArray
    }
    /// execute with dictionary parameters
    @discardableResult
    public class func database(_ databaseQueue: FMDatabaseQueue, execute: String, withArgumentsInDictionary args: [String: Any]?) -> Bool {
        
        var isSuccess = false
        databaseQueue.inTransaction { (db: FMDatabase?, roolback: UnsafeMutablePointer<ObjCBool>?) in
            guard let db = db else {
                return
            }
            isSuccess = db.executeUpdate(execute, withParameterDictionary: args ?? [:])
        }
        return isSuccess
    }
    /// execute with array parameters
    @discardableResult
    public class func database(_ databaseQueue: FMDatabaseQueue, execute: String, withArgumentsInArray args: [Any]?) -> Bool {
        var isSuccess = false
        databaseQueue.inTransaction { (db: FMDatabase?, roolback: UnsafeMutablePointer<ObjCBool>?) in
            guard let db = db else {
                return
            }
            isSuccess = db.executeUpdate(execute, withArgumentsIn: args ?? [])
        }
        return isSuccess
    }
}
