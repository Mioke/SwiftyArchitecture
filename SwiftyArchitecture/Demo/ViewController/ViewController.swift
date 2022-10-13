//
//  ViewController.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import MIOSwiftyArchitecture

open class ViewController: UIViewController {
    
    open override func viewWillAppear(_ animated: Bool) {
        KitLogger.info("\(self) will appear")
        super.viewWillAppear(animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        KitLogger.info("\(self) did appear")
        super.viewDidAppear(animated)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        KitLogger.info("\(self) will disappear")
        super.viewWillDisappear(animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        KitLogger.info("\(self) did disappear")
        super.viewDidDisappear(animated)
    }
    
    deinit {
        KitLogger.info()
    }
}



