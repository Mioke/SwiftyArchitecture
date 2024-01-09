//
//  RealmTests.swift
//  SAD
//
//  Created by KelanJiang on 2023/4/10.
//  Copyright © 2023 KleinMioke. All rights reserved.
//

import Foundation
import RealmSwift
import RxRealm
import MIOSwiftyArchitecture
import RxSwift

class RealmTests {
    
    static let shared: RealmTests = .init()
        
    let api = API<UserAPI>.init()
    let disposables: DisposeBag = .init()
    
    func testObjectChanges() {
        
        let request = Request<User>.init(params: .init(uids: ["10025"]))
        
        DataCenter.update(with: request)
            .subscribe { event in
                print(event)
            }
            .disposed(by: disposables)
    }
}
