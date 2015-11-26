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
    
    typealias receivDataType
    
    func doTask(task: () -> receivDataType, identifier: String) -> Void
    
    func doTask(task: () -> receivDataType, callBack: (receivDataType) -> Void) -> Void
    
    func finishTaskWithReuslt(result: receivDataType, identifier: String) -> Void
}
