//
//  TestObjModifyVC.swift
//  SAD
//
//  Created by KelanJiang on 2020/4/17.
//  Copyright © 2020 KleinMioke. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxRealm
import RealmSwift

class TestObjModifyVC: UIViewController {

    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    
    var objectKey: String = ""
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        bindData()
        valueTextField.delegate = self
    }
    
    func bindData() -> Void {
        let obj = AppContext.current.store.object(with: objectKey, type: TestObj.self).compactMap { $0 }
        
        obj.map { $0.key }
            .bind(to: self.keyLabel.rx.text)
            .disposed(by: self.disposeBag)
        
        obj.map { "\($0.value)" }.asDriver(onErrorJustReturn: "")
            .drive(valueTextField.rx.text)
            .disposed(by: self.disposeBag)
        
        let editingEnd = valueTextField.rx
            .controlEvent(UIControl.Event.editingDidEnd)
            .map { [weak self] in self?.valueTextField.text }
        
//        editingEnd
//            .compactMap { (text) -> UITextField? in
//                if let text = text, let _ = Int(text) {
//                    return nil
//                }
//                return self.valueTextField
//            }
//            .withLatestFrom(obj)
//            .subscribe(onNext: { (testObj) in
//                self.valueTextField.text = "\(testObj.value)"
//            })
//            .disposed(by: self.disposeBag)
            
        
        Observable
            .combineLatest(obj, editingEnd)
            .subscribe(onNext: { [weak self] (testObj, text) in
                if let text = text, let value = Int(text) {
                    try? AppContext.current.store.db.realm.safeWrite { rlm in
                        testObj.value = value
                    }
                } else {
                    self?.valueTextField.text = "\(testObj.value)"
                }
            })
            .disposed(by: self.disposeBag)
        
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

extension TestObjModifyVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
