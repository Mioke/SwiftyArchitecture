//
//  InternalTestVC.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/10.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import UserNotifications

class InternalTestVC: UIViewController, ApiCallbackProtocol {
    
    var tests: [String]!
    
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tests = ["Record user model", "Read users", "API test", "Call Log UI", "Crash", "Cache size", "Push local notification"]
        
        self.tableView = {
            let view = UITableView(frame: self.view.bounds)
            view.delegate = self
            view.dataSource = self
            view.tableFooterView = UIView()
            view.backgroundColor = UIColor.color(fromHexString: "#ff6262")
            
            self.view.addSubview(view)
            return view
        }()
        
        var a = [5, 2, 0, 1, 3, 4, 6]
//        a.quickSort(0, to: a.count-1)
//        a.heapSort()
        a.shellSort()
//        a.insertionSort()
        
        let str =  "1234567890"
        print(str[0..<2])
        
        NotificationService.current().requestAuthorization()
        
        if #available(iOS 10.0, *) {
            NotificationService.current().setRequestCompletion { (granted, error) in
                
            }
        }
        
        let b = [1, 2, 3]
        print(a.intersection(with: b))
        print(a.minus(with: b))
        print(a.union(with: b))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - APICallbacks
       
    func API(_ api: API, finishedWithOriginData data: [String : Any]) {
        debugPrint(data)
    }
    
    func API(_ api: API, failedWithError error: NSError) {
        debugPrint(error)
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    // MARK: Cell
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tests.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "titleCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "titleCell")
        }
        cell!.textLabel?.text = self.tests[indexPath.row]
        
        return cell!
    }
    
    // MARK: Action
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            let table = UserTable()
            let newUser = UserModel(name: "Klein", uid: 310)
            
            let _ = table.replace(newUser)
            
        case 1:
            let table = UserTable()
            let condition = DatabaseCommandCondition()
            
            condition.whereConditions = "user_id >= 0"
            condition.orderBy = "user_name"
            
            let result = table.queryRecord(with: nil, condition: condition)
            
            print(result)
        case 2:
            let api = TestAPI()
            api.delegate = self
            // you can't get any data from here because baidu.com 
            // return a html page instead of json data.
            _ = api.loadData(with: nil)
            break
        case 3:
            SystemLog.activeDevelopUI()
        case 4:
//            let a: [Any] = []
//            _ = a[1]
            break
        case 5:
            print(NetworkCache.memoryCache.size())
        case 6:
            if #available(iOS 10.0, *) {
                
                let content = UNMutableNotificationContent()
                content.title = "this is title"
                content.body = "this's body"
                content.subtitle = "this's subtitle"
                content.sound = .default
                
//                let date = Calendar.current.dateComponents(in: TimeZone.current, from: Date().addingTimeInterval(10))
//                let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4, repeats: false)
                
                let request = UNNotificationRequest(identifier: "test", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error: Error?) in
                    print("\(String(describing: error))")
                })
                
            } else {
                // Fallback on earlier versions
            }
            
        default:
            break
        }
    }
}
