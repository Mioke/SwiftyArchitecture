//
//  InternalTestVC.swift
//  swiftArchitecture
//
//  Created by Klein Mioke on 15/12/10.
//  Copyright © 2015年 KleinMioke. All rights reserved.
//

import UIKit
import UserNotifications
import MIOSwiftyArchitecture
import Swinject
import RxSwift
import AuthProtocol
import FLEX

class InternalTestVC: ViewController {
    
    var tests: [String]!
    
    var tableView: UITableView!
    
    let queue1 = DispatchQueue.init(label: "Queue1")
    let queue2 = DispatchQueue.init(label: "Queue2")
    
    lazy var schedule1 = SerialDispatchQueueScheduler(queue: self.queue1, internalSerialQueueName: "schedule.queue1")
    lazy var schedule2 = SerialDispatchQueueScheduler(queue: self.queue2, internalSerialQueueName: "schedule.queue2")
    
    let cancel: DisposeBag = .init()
    
    var continuations: [CheckedContinuation<Int, Never>] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "SwiftyArchitecture Demo"
//        self.navigationItem.titleView = {
//            let v = UIView(frame: .init(x: 0, y: 0, width: 200, height: 88))
//            let label = UILabel()
//            label.font = UIFont(name: "Snell Roundhand", size: 32)
//            label.text = "Swifty"
//            v.addSubview(label)
//
//            label.centerYAnchor.constraint(equalTo: v.centerYAnchor).isActive = true
//            label.centerXAnchor.constraint(equalTo: v.centerXAnchor).isActive = true
//            return v
//        }()
        
        self.tests = [
            "None1", "None2", "API test", "Call Log", "Data center test", "Theme",
            "Push local notification", "Auth Tests", "Smooth Scrolling TableView Test", "Code Block Editor",
            "Show FLEX", "Concurrency Tests", "Combine Tests",
        ]
        
        self.tableView = {
            let view = UITableView(frame: self.view.bounds)
            view.delegate = self
            view.dataSource = self
            view.tableFooterView = UIView()
            view.backgroundColor = ThemeUI.current.color.background
            
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
        
        ModuleManager.default.initiator.setPresentedFirstFrame()
        
        Observable<Int>.create { observer in
            dispatchPrecondition(condition: .onQueue(self.queue1))
            observer.onNext(1)
            observer.onCompleted()
            return Disposables.create()
        }
        .subscribe(on: schedule1)
        .observe(on: schedule2)
        .flatMapLatest({ value -> Observable<Int> in
            dispatchPrecondition(condition: .onQueue(self.queue2))
            return Observable<Int>.just(value + 1)
        })
        .subscribe(on: schedule2) // not work as expected
        .subscribe { event in
            print(event)
            dispatchPrecondition(condition: .onQueue(self.queue2))
        }
        .disposed(by: cancel)
        
        let user = AuthProtocol.TestUser.init(id: "123123", age: 1, token: "123")
        let clazzName = String(describing: type(of: user))
        let objcClazzName = NSStringFromClass(type(of: user))
        print(":", clazzName, objcClazzName, String(reflecting: user), String(reflecting: type(of: user)))
        // : User AuthProtocol.User AuthProtocol.User AuthProtocol.User
        print(Bundle.main.classNamed(objcClazzName) as Any) // x
        print(Bundle.allBundles.compactMap { $0.classNamed(clazzName) }) // x
        print(NSClassFromString(objcClazzName) as Any) // only this worked for frameworks?
        
//        UIDetector.shared.startMonitor()
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
//            sleep(1)
//        })
        
        print("1. start")
        
        Observable<Int>.create { observer in
            print("2. Subscriptoin logic")
            observer.onNext(1)
            observer.onCompleted()
            return Disposables.create()
        }
        .flatMapLatest { value -> Observable in
            print("3. flatmap")
            return .just(value * 2)
        }
        .subscribe { value in
            print("4. observe")
        }
        .disposed(by: rx.lifetime)
        
        print("5. end")
        
        print("========================")
        
        print("1. start")
        let subject = PublishSubject<Int>()
        subject.flatMapLatest { value -> Observable in
            print("3. flatmap")
            return .just(value)
        }
        .subscribe { _ in
            print("4. observe")
        }
        .disposed(by: rx.lifetime)
        print("2. send")
        subject.onNext(1)
        print("5. end")
        
        print("========================")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "titleCell") ??
            UITableViewCell(style: .default, reuseIdentifier: "titleCell")
        cell.textLabel?.text = self.tests[indexPath.row]
        return cell
    }
    
    // MARK: Action
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            do {
                let jsonString = """
                         { "name": "The Lord of the Rings" }
                         """
                if let data = jsonString.data(using: .utf8) {
                    let video = try JSONDecoder().decode(Video.self, from: data)
                    print(video.name, video.state)
                }
            } catch {
                print(error)
            }
        case 1:
//            let table = UserTable()
//            let condition = DatabaseCommandCondition()
//            
//            condition.whereConditions = "user_id >= 0"
//            condition.orderBy = "user_name"
//            
//            let result = table.queryRecord(with: nil, condition: condition)
//            
//            print(result)
            break
        case 2:
            let api = API<TestAPI>()
            // you can't get any data from here because baidu.com 
            // return a html page instead of json data.
            api.sendRequest(with: nil).response({ (api, result, error) in
                if let result = result {
                    print(result.isFinal, result.objects)
                }
            })
        case 3:
            KitLogger.log(level: .info, message: "Info messages.")
            KitLogger.log(level: .debug, message: "Debug messages.")
            KitLogger.log(level: .error, message: "Error messages.")
            KitLogger.log(level: .verbose, message: "Verbose messages.")
            break
            
        case 4:
            let vc = DataCenterTestViewController()
            self.navigationController?.pushViewController(vc, animated: true)
            
        case 5:
//            print(NetworkCache.memoryCache.size())
//            let signal =
//            Observable<Int>.create { observer in
//                print(1)
//                observer.onNext(2)
//                return Disposables.create()
//            }
//            .subscribe(on: schedule1)
//            .observe(on: MainScheduler.instance)
//            .flatMapLatest { value -> Observable<Int> in
//                print(2)
//                dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
//                return .just(3)
//            }
//
//            signal.subscribe().disposed(by: cancel)
//            print(3)
            
            let url = "sa-interal://com.mioke.swifty-architecture-demo/home/theme"
            let navi = navigation!.createNavigationURL(withModule: "home", paths: ["theme"])
            if navi.absoluteString != url {
                KitLogger.error("not matched: \n\(navi.absoluteString)\n\(url)")
                fatalError()
            }
            
            do {
                try navigation!.navigate(to: url) { result in
                    KitLogger.info("result: \(result)")
                }
            } catch {
                KitLogger.error("error: \(error)")
            }
            
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
        case 7:
            let vc = AuthTestViewController(nibName: nil, bundle: nil)
            self.navigationController?.pushViewController(vc, animated: true)
            
        case 8:
            let url = "sa-interal://com.mioke.swifty-architecture-demo/home/messages"
            var config = Navigation.Configuration.default
            config.presentationMode = .push
            try! navigation!.navigate(to: url, configuration: config)
        case 9:
            let vc = CodeBlockEditorViewController(nibName: nil, bundle: nil)
            self.navigationController?.pushViewController(vc, animated: true)
        case 10:
            FLEXManager.shared.showExplorer()
        case 11:
            navigationController?.pushViewController(ConcurrencyTestViewController(), animated: true)
        case 12:
            navigationController?.pushViewController(CombineTestsViewController(), animated: true)
        default:
            break
        }
    }
}

protocol ColorTheme {
    var primary: UIColor { get }
}

struct LightTheme: ColorTheme {
    var primary: UIColor {
        return .white
    }
}

class TestCase1 {
    func getColor(keyPath: KeyPath<ColorTheme, UIColor>) -> UIColor {
        return LightTheme()[keyPath: keyPath]
    }
    
    func usage() {
        let primary = getColor(keyPath: \ColorTheme.primary)
        print(primary)
    }
}
