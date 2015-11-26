//
//  KMViewController.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/11/23.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

class KMViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension KMViewController: TaskExecutor {
    
    typealias receivDataType = AnyObject
    
    func doTask(task: () -> receivDataType, identifier: String) {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) { () -> Void in
            
            let result = task()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.finishTaskWithReuslt(result, identifier: identifier)
            })
        }
    }
    
    func doTask(task: () -> receivDataType, callBack: (receivDataType) -> Void) {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) { () -> Void in
            
            let result = task()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callBack(result)
            })
        }
    }
    
    func finishTaskWithReuslt(result: receivDataType, identifier: String) {
        
        if let _ = (result as? ResultType<receivDataType>)?.error() {
//            do base processing like
//            if error.code == 001 {
//                
//            }
        }
    }
}



