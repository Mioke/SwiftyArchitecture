//
//  Combine.swift
//  SAD
//
//  Created by KelanJiang on 2023/6/27.
//  Copyright © 2023 KleinMioke. All rights reserved.
//

import Foundation
import Combine


class TestCombineUsages {
    
    static let shared: TestCombineUsages = .init()
    
    var cancelables: [AnyCancellable] = []
    
    @Published var count: Int = 0
    
    private init() {
        foo2()
    }
    
    func foo() {
        let publisher: NotificationCenter.Publisher = .init(center: .default,
                                                            name: UIResponder.keyboardWillShowNotification)
        
        publisher
            .receive(on: RunLoop.main)
            .sink { completion in
                print(completion)
            } receiveValue: { value in
                print(value)
            }
            .store(in: &cancelables)

    }
    
    var subscriber: AnySubscriber<Int, Never> = AnySubscriber(
        receiveSubscription: { subscription in
            print(subscription)
        },
        receiveValue: { value in
            print(3, value)
            return .unlimited
        },
        receiveCompletion: { completion in
            print(completion)
        })
    
    func foo2() {
//
//        $count
//            .handleEvents { subscription in
//                print("subscription", subscription)
//            } receiveOutput: { value in
//                print("output", value)
//            } receiveCancel: {
//                print("cancel")
//            } receiveRequest: { demand in
//                print("demand", demand)
//            }
//            .subscribe(subscriber)
            
        $count.subscribe(subscriber)
        
        $count
            .handleEvents { subscription in
                print("subscription", subscription)
            } receiveOutput: { value in
                print("output", value)
            } receiveCancel: {
                print("cancel")
            } receiveRequest: { demand in
                print("demand", demand)
            }
            .sink { value in
                print(1, value)
            }
            .store(in: &cancelables)
        
        $count
            .sink { value in
                print(2, value)
            }
            .store(in: &cancelables)
        
        
    }
    
    func foo3() {
        CTUser()
            .combine
            .name
            .sink { (value: String?) in

        }
            .store(in: &cancelables)
        
    }
}

class CTUser: NSObject {
    var name: String?
}

