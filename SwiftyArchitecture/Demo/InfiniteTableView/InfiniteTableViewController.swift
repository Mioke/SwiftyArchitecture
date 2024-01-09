//
//  InfiniteTableViewController.swift
//  SAD
//
//  Created by KelanJiang on 2022/10/11.
//  Copyright © 2022 KleinMioke. All rights reserved.
//

import UIKit

let alphanumberic = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

class MessageViewModel {
    
    let message: String
    
    init(message: String) {
        self.message = message
    }
    
    convenience init() {
        self.init(message: (0..<Int.random(in: 50..<100))
            .compactMap { _ in String(alphanumberic.randomElement() ?? Character.init(""))}
            .joined())
    }
}

class MessageCell: UITableViewCell {
    let messageLabel: UILabel = .init()
    
    static let colors: [UIColor] = [.magenta, .red, .green, .blue, .orange, .systemPink, .purple, .brown, .systemCyan, .systemYellow, .systemMint, .systemOrange, .gray, .darkGray, .link, .lightGray]
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
//        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(messageLabel)
        messageLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15).isActive = true
        messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15).isActive = true
        messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15).isActive = true
        
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        contentView.backgroundColor = Self.colors.randomElement() ?? .clear
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = Self.colors.randomElement() ?? .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class InfiniteTableViewController: ViewController, UITableViewDelegate, UITableViewDataSource {

    var data: [MessageViewModel] = []
    
    let tableView: UITableView = .init(frame: .zero, style: .plain)
    
    static let pageSize: Int = 50
    let pageSize: Int = 50
    var pageCount: Int = 2
    
    var currentPage: Int = 0
    var isUpdating = false {
        didSet {
            print("table view updating state changed \(isUpdating)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = "Messages"
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
//        tableView.estimatedRowHeight = 60
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.showsVerticalScrollIndicator = false
        
        data = gen(count: pageSize * pageCount)
        
        tableView.reloadData()
        tableView.scrollToRow(at: .init(row: data.count - 1, section: 0), at: .bottom, animated: false)
    }
    
    func gen(count: Int) -> [MessageViewModel] {
        return (0..<count).map { _ in
            MessageViewModel()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as? MessageCell else {
            return .init()
        }
        let number = data.count - 1 - indexPath.row
        cell.messageLabel.text = data[number].message
        return cell
    }
    

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
//    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 60
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    static let indexPaths = (0..<pageSize).map { IndexPath(row: $0, section: 0) }
    
    var lastLoadedIndexPath: IndexPath? = nil
}


extension InfiniteTableViewController {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        defer { lastLoadedIndexPath = indexPath }
        
        let rowOfGoingToShow = indexPath.row
        let all = data.count
        
        // The row number of data, reverse order.
        let row = (all - 1) - rowOfGoingToShow
        
        currentPage = row / pageSize
        
        // filter with the direction - scrolling upward
        guard let last = lastLoadedIndexPath, last.row > indexPath.row else { return }
        
        guard !isUpdating, currentPage == pageCount - 1 else { return }
        
        let numberInCurrentPage = row % pageSize
        
        if numberInCurrentPage * 2 > pageSize {
            loadNextPage()
        }
    }
    
    func loadNextPage() -> Void {
        isUpdating = true
        pageCount += 1
        
        DispatchQueue.global().async { [self] in
            let new = gen(count: pageSize)
            DispatchQueue.main.async { [self] in
                data.append(contentsOf: new)
                
//                UIView.setAnimationsEnabled(false)
                tableView.performBatchUpdates {
                    tableView.insertRows(at: Self.indexPaths, with: .none)
//                    UIView.setAnimationsEnabled(true)
                } completion: { finished in
                    self.isUpdating = false
                }
                
            }
        }
    }
}

extension InfiniteTableViewController: NavigationTargetProtocol {
    static func createTarget(
        subPaths: [String],
        queries: [NavigationURL.QueryItem],
        configuration: Navigation.Configuration)
    -> [UIViewController] {
        if case .present = configuration.presentationMode {
            let nav = UINavigationController(rootViewController: InfiniteTableViewController())
            return [nav]
        }
        return [InfiniteTableViewController()]
    }
}
