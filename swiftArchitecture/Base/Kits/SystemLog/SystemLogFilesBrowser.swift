//
//  SystemLogFilesBrowser.swift
//  swiftArchitecture
//
//  Created by jiangkelan on 3/8/16.
//  Copyright © 2016 KleinMioke. All rights reserved.
//

import UIKit
/// A view controller for displaying log files's list
public class SystemLogFilesBrowser: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let tableView: UITableView = UITableView()
    var files = [String]()

    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.files.append(contentsOf: SystemLog.allLogFiles() ?? [])
        
        self.tableView.frame = self.view.bounds
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view.addSubview(self.tableView)
        
        self.navigationItem.setLeftBarButton(UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(SystemLogFilesBrowser.close)), animated: false)
    }
    
    public func close() -> Void {
        self.dismiss(animated: true, completion: nil)
    }


    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TableView's delegate & datasource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") {
            cell.textLabel?.text = self.files[indexPath.row]
            return cell
        } else {
            let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
            cell.textLabel?.text = self.files[indexPath.row]
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = SystemLogBrowser()
        vc.fileName = self.files[indexPath.row]
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
