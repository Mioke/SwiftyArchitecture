//
//  DatabaseManager.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/1.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation
import FMDB

class DatabaseManager: NSObject {
    
    class func database(_ databaseQueue: FMDatabaseQueue, query: String, withArgumentsInArray args: [Any]?) -> NSMutableArray {
        
        let rstArray = NSMutableArray()
        
        databaseQueue.inTransaction { (db: FMDatabase?, roolback: UnsafeMutablePointer<ObjCBool>?) in
            guard let db = db else {
                return
            }
            if let rst = db.executeQuery(query, withArgumentsIn: args) {
                while rst.next() {
                    rstArray.add(rst.resultDictionary())
                }
                rst.close()
            }
        }
        return rstArray
    }
    
    class func database(_ databaseQueue: FMDatabaseQueue, execute: String, withArgumentsInDictionary args: [String: Any]!) -> Bool {
        
        var isSuccess = false
        databaseQueue.inTransaction { (db: FMDatabase?, roolback: UnsafeMutablePointer<ObjCBool>?) in
            guard let db = db else {
                return
            }
            isSuccess = db.executeUpdate(execute, withParameterDictionary: args)
        }
        return isSuccess
    }
    
    class func database(_ databaseQueue: FMDatabaseQueue, execute: String, withArgumentsInArray args: [Any]!) -> Bool {
        var isSuccess = false
        databaseQueue.inTransaction { (db: FMDatabase?, roolback: UnsafeMutablePointer<ObjCBool>?) in
            guard let db = db else {
                return
            }
            isSuccess = db.executeUpdate(execute, withArgumentsIn: args)
        }
        return isSuccess
    }
}
