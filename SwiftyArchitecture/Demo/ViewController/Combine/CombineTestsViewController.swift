//
//  CombineTestsViewController.swift
//  SAD
//
//  Created by KelanJiang on 2023/6/27.
//  Copyright © 2023 KleinMioke. All rights reserved.
//

import UIKit

class CombineTestsViewController: UIViewController {
    
    let manager = TestCombineUsages.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let array: [Int] = []
        let set: Set<Int> = .init(array)
        let unique = Array<Int>.init(set)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        manager.count += 1
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

//protocol Notifiable {
//    associatedtype Value
//
//    func subscribe() -> any AsyncSequence
//}

protocol Notifiable<Value> {
    associatedtype Value
    func subscribe() -> any AsyncSequence
//    var sequence: [Value] { get }
}

class Notifier: Notifiable {
    func subscribe() -> any AsyncSequence {
        return AsyncStream<Value>.init { continuation in
            
        }
    }
    
    typealias Value = Notification
    
    func nonProtocolSubscribe() -> some AsyncSequence {
        return AsyncStream<Value>.init { continuation in
            
        }
    }
    
    func someSubsuribe(observer: some Notifiable<Int>) {
        
    }
    
    func foo() {
        nonProtocolSubscribe().map { element in
            
        }
    }
    
}
