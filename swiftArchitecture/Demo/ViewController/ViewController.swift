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
    
    var loginManager: ApiLogin!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        scope("init UI") {
            self.view.backgroundColor = UIColor.lightGray
        }
        
        scope("init data") {
            self.loginManager = {
                let manager = ApiLogin()
                manager.delegate = self
                return manager
            }()
        }
        
        let db = DefaultDatabase()
        Log.debugPrintln(db.query("select * from tableDoesntExtist", withArgumentsInArray: nil))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clickButton(_ sender: AnyObject) {
        
//        self.doTask({ () -> receiveDataType in
//            
//            return try self.userService.login()
//            
//        }, identifier: "LoginAction")
        
//        self.loginManager.loadDataWithParams([
//            "ver": "i5.1.1",
//            "account": "1223@ss.com",
//            "password": "111111",
//            "device": "12345"
//        ])
    }
    
//    override func finishTaskWithReuslt(result: receiveDataType, identifier: String) {
    
//        if identifier == "LoginAction" {
//            
//            if let result = result as? Bool where result {
//                print("login success")
//            } else {
//                print("login failed")
//            }
//        }
//    }
    
//    override func taskCancelledWithError(error: ErrorResultType, identifier: String) {
//        super.taskCancelledWithError(error, identifier: identifier)
//    }
}

extension ViewController: ApiCallbackProtocol {
    
    func ApiManager(_ apiManager: BaseApiManager, finishWithOriginData data: AnyObject) {
        
        if let apiManager = apiManager as? ApiLogin {
            print("login success: \n \(apiManager.originData())")
        }
    }
    
    func ApiManager(_ apimanager: BaseApiManager, failedWithError error: NSError) {
        
    }
}


