//
//  Internal.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/3.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

protocol XProtocol {
    
    func dealError(error: ErrorResultType)
}

extension UIViewController: XProtocol {
    
    func dealError(error: ErrorResultType) {
        
    }
}

class ABCViewController: UIViewController {
    
    override func dealError(error: ErrorResultType) {
        
    }
}