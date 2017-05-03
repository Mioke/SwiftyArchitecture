//
//  TaskManageProtocols.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

public protocol _task: NSObjectProtocol {
    associatedtype receiveDataType
}

public protocol sender: _task {
    
//    func doTask(task: () throws -> receiveDataType, identifier: String) -> Void
    
//    func doTask(task: () throws -> receiveDataType, callBack: (receiveDataType) -> Void, failure: (ErrorResultType) -> Void) -> Void
    
    //    func cancelTaskWithIdentifier(identifier: String) -> Bool
}

public protocol receiver: _task {
    
//    func taskCancelledWithError(error: ErrorResultType, identifier: String) -> Void
    
//    func finishTaskWithReuslt(result: receiveDataType, identifier: String) -> Void
}

