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
    
    var baiduSearch = TestAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        scope("init UI") {
            self.view.backgroundColor = UIColor.lightGray
        }
        
        scope("init data") {
            self.baiduSearch.loadData(with: nil)
        }
        
        let db = DefaultDatabase()
        Log.debugPrintln(db.query("select * from tableDoesntExtist", withArgumentsInArray: nil))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clickButton(_ sender: Any) {
        
    }
}

extension ViewController: ApiCallbackProtocol {
    
    func ApiManager(_ apiManager: BaseApiManager, finishWithOriginData data: Any) {
        
        if apiManager == self.baiduSearch {
            debugPrint(data)
        }
    }
    
    func ApiManager(_ apiManager: BaseApiManager, failedWithError error: NSError) {
        if apiManager == self.baiduSearch {
            debugPrint(error)
        }
    }
}


