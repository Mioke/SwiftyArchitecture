//
//  RxTests.swift
//  MIOSwiftyArchitecture-Unit-Tests
//
//  Created by KelanJiang on 2022/6/9.
//

import Foundation
@testable import MIOSwiftyArchitecture
import XCTest
import RxSwift

class RxTestCase: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    var cancel: DisposeBag = .init()
    
    func testProducerQueue() {
        let queue = ProducerQueue<Int>()
        let expect = XCTestExpectation()
        
        let ob1 = Observable<Int>.create { observer in
            observer.onNext(1)
            observer.onNext(2)
            observer.onCompleted()
            return Disposables.create()
        }
        
        let ob2 = Observable<Int>.create { observer in
            observer.onNext(3)
            observer.onCompleted()
            return Disposables.create()
        }
        
        queue.enqueue(producer: ob1).subscribe { event in
            print(event)
        }.disposed(by: cancel)
        
        queue.enqueue(producer: ob2).subscribe { event in
            print(event)
            expect.fulfill()
        }.disposed(by: cancel)
        
        wait(for: [expect], timeout: 5)
    }
    
    func testRwQueue() -> Void {
        let queue = RwQueue(qos: .default)
        var value = 1
        let expect = XCTestExpectation()
        let scheduler = ConcurrentDispatchQueueScheduler.init(qos: .default)
        
        Observable<Void>.create { ob in
            queue.read {
                print("r1: \(value)")
            }
            return Disposables.create()
        }
        .subscribe(on: scheduler)
        .subscribe()
        .disposed(by: cancel)
        
        Observable<Void>.create { ob in
            queue.read {
                print("r2: \(value)")
            }
            return Disposables.create()
        }
        .subscribe(on: scheduler)
        .subscribe()
        .disposed(by: cancel)
        
        
        Observable<Void>.create { ob in
            queue.write {
                print("w1")
                value = 2
            }
            return Disposables.create()
        }
        .subscribe(on: scheduler)
        .subscribe()
        .disposed(by: cancel)
        
        Observable<Void>.create { ob in
            queue.read {
                print("r3: \(value)")
                XCTAssertTrue(value == 2)
                expect.fulfill()
            }
            return Disposables.create()
        }
        .delaySubscription(.seconds(1), scheduler: scheduler)
        .subscribe()
        .disposed(by: cancel)
        
        wait(for: [expect], timeout: 5)
        
    }
    
    func testRwQueue2() {
        let queue = RwQueue(qos: .default)
        let date = Date.now.timeIntervalSince1970
        let expect = XCTestExpectation()
        let scheduler = ConcurrentDispatchQueueScheduler.init(qos: .default)
        
        Observable<Void>.create { ob in
            queue.read {
                print("r")
                sleep(2)
            }
            return Disposables.create()
        }
        .subscribe(on: scheduler)
        .subscribe()
        .disposed(by: cancel)
        
        Observable<Void>.create { ob in
            queue.write {
                print("w")
                let now = Date.now.timeIntervalSince1970
                XCTAssertTrue(now - date >= 2)
                expect.fulfill()
            }
            return Disposables.create()
        }
        .delaySubscription(.milliseconds(10), scheduler: scheduler)
        .subscribe()
        .disposed(by: cancel)
        
        wait(for: [expect], timeout: 5)
    }
    
    func testRwQueue3() {
        let queue = RwQueue(qos: .default)
        let date = Date.now.timeIntervalSince1970
        let expect = XCTestExpectation()
        let scheduler = ConcurrentDispatchQueueScheduler.init(qos: .default)
        
        Observable<Void>.create { ob in
            queue.write {
                print("w")
                sleep(2)
            }
            return Disposables.create()
        }
        .subscribe(on: scheduler)
        .subscribe()
        .disposed(by: cancel)
        
        Observable<Void>.create { ob in
            queue.read {
                print("r")
                let now = Date.now.timeIntervalSince1970
                XCTAssertTrue(now - date >= 2)
                expect.fulfill()
            }
            return Disposables.create()
        }
        .delaySubscription(.milliseconds(10), scheduler: scheduler)
        .subscribe()
        .disposed(by: cancel)
        
        wait(for: [expect], timeout: 5)
    }
}

