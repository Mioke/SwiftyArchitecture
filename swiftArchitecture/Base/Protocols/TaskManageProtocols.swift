//
//  TaskManageProtocols.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

protocol _sender: NSObjectProtocol {
}

protocol _receiver: NSObjectProtocol {
}

protocol TaskExecutor: _sender, _receiver {
    
    typealias receiveDataType
    
    func doTask(task: () -> receiveDataType, identifier: String) -> Void
    
    func doTask(task: () -> receiveDataType, callBack: (receiveDataType) -> Void) -> Void
    
    func finishTaskWithReuslt(result: receiveDataType, identifier: String) -> Void
}
