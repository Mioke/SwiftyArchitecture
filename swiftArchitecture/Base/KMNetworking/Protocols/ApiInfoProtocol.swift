//
//  ApiInfoProtocol.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/7.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import Foundation

protocol ApiInfoProtocol: NSObjectProtocol {

    var apiVersion: String { get }
    var apiName: String { get }
    
    var server: Server { get }
}
