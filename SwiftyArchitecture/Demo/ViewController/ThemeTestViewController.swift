//
//  ThemeTestViewController.swift
//  SAD
//
//  Created by KelanJiang on 2022/6/21.
//  Copyright © 2022 KleinMioke. All rights reserved.
//

import UIKit
import MIOSwiftyArchitecture

class ThemeTestViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selection: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tableView.rowHeight = 44
        tableView.register(ThemeTestCell.self)
        
        tableView.reloadData()
        
        guard let dynamic = ThemeUI.current.transform(to: DynamicColors.self) else { fatalError() }
        selection.selectedSegmentIndex = dynamic.resource.currentSetting.rawValue
    }

    var dataSource: [String] = {
        (0...100).map { value in
            "Messages \(value)"
        }
    }()
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func selectionDidChange(_ sender: Any) {
        guard let segment = sender as? UISegmentedControl,
              let selection = DynamicColors.Settings.init(rawValue: segment.selectedSegmentIndex),
              let dynamic = ThemeUI.current.transform(to: DynamicColors.self)
        else { return }
        
        dynamic.update(setting: selection)
    }
}

extension ThemeTestViewController: UITableViewDelegate, UITableViewDataSource {
    
    static var textAtrributes: [NSAttributedString.Key : Any] = [
        .foregroundColor: ThemeUI.current.resource.text,
        .font: UIFont.systemFont(ofSize: 16)
    ]
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeReusableCell(forIndexPath: indexPath) as ThemeTestCell
        cell.label.attributedText = NSAttributedString(string: dataSource[indexPath.row], attributes: Self.textAtrributes)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
}

class ThemeTestCell: UITableViewCell {
    
    let label: UILabel
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.label = .init(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.label)
        self.label.textColor = ThemeUI.current.resource.text
        self.label.font = .systemFont(ofSize: 16)
        
        self.backgroundColor = ThemeUI.current.resource.background
        
        self.label.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 16).isActive = true
        self.label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.label.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ThemeTestCell: ReusableView { }
