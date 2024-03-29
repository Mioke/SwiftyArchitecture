//
//  AuthTestViewController.swift
//  SAD
//
//  Created by KelanJiang on 2022/9/2.
//  Copyright © 2022 KleinMioke. All rights reserved.
//

import UIKit
import MIOSwiftyArchitecture
import RxCocoa
import RxSwift
import AuthProtocol

class AuthTestViewController: UIViewController {

    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    
    var listeners: DisposeBag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        refreshDisplay()
    }
    
    func refreshDisplay() -> Void {
        if let user = AppContext.current.user as? TestUser {
            displayLabel.text = user.customDebugDescription
            
        } else if AppContext.current == AppContext.standard {
            displayLabel.text = "Current is default user"
        }
        
        listeners = .init()
        AppContext.current.authState.map { "\($0)" }
            .asDriver(onErrorJustReturn: "Error")
            .debug("AuthVC")
            .drive(statusLabel.rx.text)
            .disposed(by: listeners)
    }


    @IBAction func onLogin(_ sender: Any) {
        UserService.shared
            .login()
            .subscribe { event in
                switch event {
                case .next():
                    self.refreshDisplay()
                case .completed, .error:
                    break
                }
            }
            .disposed(by: self.rx.lifetime)
    }
    
    @IBAction func onRefresh(_ sender: Any) {
        
    }
    
    @IBAction func onLogout(_ sender: Any) {
        UserService.shared.logout()
            .subscribe { [weak self] event in
                if case .next = event {
                    self?.refreshDisplay()
                }
            }
            .disposed(by: rx.lifetime)
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
