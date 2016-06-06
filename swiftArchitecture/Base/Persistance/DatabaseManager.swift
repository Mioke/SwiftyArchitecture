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
    
    class func database(databaseQueue: FMDatabaseQueue, query: String, withArgumentsInArray args: [AnyObject]?) -> NSMutableArray {
        
        let rstArray = NSMutableArray()
        databaseQueue.inTransaction { (db: FMDatabase!, rollback: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            if let rst = db.executeQuery(query, withArgumentsInArray: args) {
                while rst.next() {
                    rstArray.addObject(rst.resultDictionary())
                }
                rst.close()
            }
        }
        return rstArray
    }
    
    class func database(databaseQueue: FMDatabaseQueue, execute: String, withArgumentsInDictionary args: [String: AnyObject]!) -> Bool {
        
        var isSuccess = false
        databaseQueue.inTransaction { (db: FMDatabase!, rollback: UnsafeMutablePointer<ObjCBool>) -> Void in
            isSuccess = db.executeUpdate(execute, withParameterDictionary: args)
        }
        return isSuccess
    }
    
    class func database(databaseQueue: FMDatabaseQueue, execute: String, withArgumentsInArray args: [AnyObject]!) -> Bool {
        var isSuccess = false
        databaseQueue.inTransaction { (db: FMDatabase!, rollback: UnsafeMutablePointer<ObjCBool>) -> Void in
            isSuccess = db.executeUpdate(execute, withArgumentsInArray: args)
        }
        return isSuccess
    }
}
