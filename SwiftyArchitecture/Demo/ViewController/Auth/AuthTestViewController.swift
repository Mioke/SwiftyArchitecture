//
//  AuthTestViewController.swift
//  SAD
//
//  Created by KelanJiang on 2022/9/2.
//  Copyright © 2022 KleinMioke. All rights reserved.
//

import UIKit
import MIOSwiftyArchitecture

class AuthTestViewController: UIViewController {

    @IBOutlet weak var displayLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        refreshDisplay()
    }
    
    func refreshDisplay() -> Void {
        if let user = AppContext.current.user as? TestUser {
            displayLabel.text = user.customDebugDescription
            statusLabel.text = "\(try! user.authState.value())"
            
        } else if AppContext.current == AppContext.standard {
            displayLabel.text = "Current is default user"
        }
    }


    @IBAction func onLogin(_ sender: Any) {
        UserService.shared.login()
        refreshDisplay()
    }
    
    @IBAction func onRefresh(_ sender: Any) {
        
    }
    
    @IBAction func onLogout(_ sender: Any) {
        
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
