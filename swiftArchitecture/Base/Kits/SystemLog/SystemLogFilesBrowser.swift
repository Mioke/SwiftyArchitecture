//
//  SystemLogFilesBrowser.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 3/8/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit

class SystemLogFilesBrowser: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView: UITableView = UITableView()
    var files = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.files.appendContentsOf(SystemLog.allLogFiles() ?? [])
        
        self.tableView.frame = self.view.bounds
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view.addSubview(self.tableView)
        
        self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(title: "Close", style: .Plain, target: self, action: #selector(SystemLogFilesBrowser.close)), animated: false)
    }
    
    func close() -> Void {
        self.dismissViewControllerAnimated(true, completion: nil)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TableView's delegate & datasource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("cell") {
            cell.textLabel?.text = self.files[indexPath.row]
            return cell
        } else {
            let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
            cell.textLabel?.text = self.files[indexPath.row]
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let vc = SystemLogBrowser()
        vc.fileName = self.files[indexPath.row]
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
