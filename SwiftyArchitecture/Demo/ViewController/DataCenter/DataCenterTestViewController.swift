//
//  DataCenterTestVCViewController.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/13.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import RxRealm
import MIOSwiftyArchitecture
import RealmSwift

extension TestObj: IdentifiableType {
    typealias Identity = String
    var identity: String {
        return self.key
    }
}

class DataCenterTestViewModel: NSObject {
    
}

class DataCenterTestCell: UITableViewCell {
    var valueLabel: UILabel!
    var reset: DisposeBag = .init()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        valueLabel = UILabel()
        contentView.addSubview(valueLabel)
        
        valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reset = .init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DataCenterTestCell: ReusableView { }


class DataCenterTestViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    typealias Section = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, TestObj>>
    let datasource = Section(configureCell: { datasource, tableView, indexPath, item in
        
        let cell = tableView.dequeReusableCell(forIndexPath: indexPath) as DataCenterTestCell
        
        Observable<TestObj>.from(object: item, emitInitialValue: true)
            .subscribe(onNext: { [weak cell] object in
                cell?.textLabel?.text = item.key
                cell?.valueLabel?.text = "\(item.value)"
            })
            .disposed(by: cell.reset)
        
        return cell
    })
    
    let disposeBag: DisposeBag = DisposeBag()
    
    var objs: [TestObj] = [] {
        didSet {
            relay.accept(objs)
        }
    }
    
    lazy var relay: BehaviorRelay<[TestObj]> = {
        return BehaviorRelay(value: objs)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let button = UIBarButtonItem(
            title: "Add",
            style: UIBarButtonItem.Style.plain,
            target: self,
            action: #selector(addSomeObj))
        let refreshItem = UIBarButtonItem(
            title: "Refresh",
            style: .plain,
            target: self,
            action: #selector(refresh))
        self.navigationItem.rightBarButtonItems = [button, refreshItem]
        
        tableView.register(DataCenterTestCell.self,
                           forCellReuseIdentifier: DataCenterTestCell.reusedIdentifier)
        
        Accessor<TestObj>.context(.cache).all
            .map { $0.sorted(by: <) }
            .map { [AnimatableSectionModel(model: "", items: $0)] }
            .bind(to: tableView.rx.items(dataSource: datasource))
            .disposed(by: disposeBag)

        tableView.rx
            .modelSelected(TestObj.self)
            .map { $0.key }
            .bind { (key) in
                let vc = TestObjModifyVC()
                vc.objectKey = key
                self.navigationController?.pushViewController(vc, animated: true)
        }.disposed(by: self.disposeBag)
        

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    func createObj() -> TestObj {
        let key = "Key random \(arc4random())"
        let obj = TestObj(with: key)
        obj.value = Int(arc4random())
        return obj
    }
    
    @objc func addSomeObj() -> Void {
        
        let obj = createObj()
        Observable.just(obj)
            .subscribe(try! AppContextCurrentCache().rx.add())
            .disposed(by: self.disposeBag)
        
//        try? AppContext.current.db.realm.write {
//            AppContext.current.db.realm.add(obj)
//        }
//        objs.append(createObj())
        
        var racers: [Racer] = []
        
        let aDog = Dog(speed: 100)
        racers.append(aDog)
        
        let aMan = Human(speed: 80)
        racers.append(aMan)
        
        _ = racers.fastest()
//        racers.bla()
        
        let humans = [Human]()
        humans.bla()
        _ = (humans as [Racer]).fastest()
//        humans.fastest()
    }

    @objc func refresh() -> Void {
        print("Show loading")
        RealmTests.shared.testObjectChanges()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

protocol Racer {
    var speed: Double { get }
}

extension Sequence where Iterator.Element == Racer {
    func fastest() -> Iterator.Element? {
        return self.max { $0.speed < $1.speed}
    }
}

extension Sequence where Iterator.Element: Racer {
    func bla() -> Void {

    }
}

struct Human: Racer {
    var speed: Double
}

struct Dog: Racer {
    var speed: Double
}
