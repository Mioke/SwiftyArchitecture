//
//  ViewController.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let userService = UserService()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        scope("init UI") {
            self.view.backgroundColor = UIColor.lightGrayColor()
        }
        
        let db = DefaultDatabase()
        Log.debugPrintln(db.query("select * from tableDoesntExtist", withArgumentsInArray: nil))
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clickButton(sender: AnyObject) {
        
//        //尽量不要使用block回调，保证结构统一性。To make sure the unitarity of callback ,don't use this except neccesary
//        self.doTask({ () -> receiveDataType in
//            
//            return UserService.sharedInstance.login()
//
//        }) { (result: receiveDataType) -> Void in
//            
//            if let result = result as? Bool where
//                result {
//                print("login success")
//            } else {
//                print("login failed")
//            }
//        }
        
        // or
        
        self.doTask({ () -> receiveDataType in
            
            return self.userService.login()
            
        }, identifier: "LoginAction")
    }
    
    override func finishTaskWithReuslt(result: receiveDataType, identifier: String) {
        
        // Dealing error
        super.finishTaskWithReuslt(result, identifier: identifier)
        
        if identifier == "LoginAction" {
            
            if let result = result as? Bool where result {
                print("login success")
            } else {
                print("login failed")
            }
        }
    }
}



