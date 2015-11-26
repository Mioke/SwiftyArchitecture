//
//  ViewController.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

class ViewController: KMViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clickButton(sender: AnyObject) {
        
        self.doTask({ () -> receivDataType in
            
            return UserService.sharedInstance.login()

        }) { (result: receivDataType) -> Void in
            
            if let result = result as? Bool where
                result {
                print("login success")
            } else {
                print("login failed")
            }
        }
    }
}



