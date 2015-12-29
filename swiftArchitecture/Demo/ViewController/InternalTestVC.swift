//
//  InternalTestVC.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/10.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit

class InternalTestVC: UIViewController, ApiCallbackProtocol {
    
    var tests: [String]!
    
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tests = ["Record user model", "Read users", "login"]
        
        self.tableView = {
            let view = UITableView(frame: self.view.bounds)
            view.delegate = self
            view.dataSource = self
            
            self.view.addSubview(view)
            return view
        }()
        
        var a = [5, 2, 0, 1, 3, 4, 6]
//        a.quickSort(0, to: a.count-1)
//        a.heapSort()
        a.shellSort()
//        a.insertionSort()
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

extension InternalTestVC: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - UITableView's delegate & datasource
    
    // MARK: Header
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    // MARK: Cell
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tests.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("titleCell")
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "titleCell")
        }
        cell!.textLabel?.text = self.tests[indexPath.row]
        
        return cell!
    }
    
    // MARK: Action
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch indexPath.row {
        case 0:
            let table = UserTable()
            let newUser = UserModel(name: "Klein", uid: 310)
            
            table.replaceRecord(newUser)
            
        case 1:
            let table = UserTable()
            let condition = DatabaseCommandCondition()
            
            condition.whereConditions = "user_id >= 0"
            condition.orderBy = "user_name"
            
            let result = table.queryRecordWithSelect(nil, condition: condition)
            
            Log.debugPrintln(result)
        case 2:
            let api = ApiLogin()
            api.delegate = self
            api.loadDataWithParams([
                "ver": "i5.1.1",
                "account": "1223@ss.com",
                "password": "111111",
                "device": "12345"
            ])
            
        default:
            break
        }
    }
    
    // MARK: - APICallbacks
    
    func ApiManager(apiManager: BaseApiManager, finishWithOriginData data: AnyObject) {
        
    }
    
    func ApiManager(apimanager: BaseApiManager, failedWithError error: NSError) {
        
    }
}
