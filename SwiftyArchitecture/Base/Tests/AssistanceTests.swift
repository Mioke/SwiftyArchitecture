//
//  APITests.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/5/30.
//

import Foundation
@testable import MIOSwiftyArchitecture
import XCTest
import RxSwift
import Alamofire

class AssistanceTests: XCTestCase {
    
    var cancel: DisposeBag = .init()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRwLock() {
        var value = 1
        let lock = RwLock()
        let scheduler = ConcurrentDispatchQueueScheduler.init(qos: .default)
        let expect = XCTestExpectation()
        
        Observable<Void>.create { ob in
            lock.read {
                print(1, value)
            }
            return Disposables.create()
        }.subscribe(on: scheduler).subscribe().disposed(by: cancel)
        
        Observable<Void>.create { ob in
            lock.read {
                print(2, value)
            }
            return Disposables.create()
        }.subscribe(on: scheduler).subscribe().disposed(by: cancel)
        
        Observable<Void>.create { ob in
            lock.write {
                print("changing")
                value = 2
            }
            lock.read {
                XCTAssertTrue(value == 2)
                expect.fulfill()
            }
            return Disposables.create()
        }.subscribe(on: scheduler).subscribe().disposed(by: cancel)
        
        wait(for: [expect], timeout: 5)
    }
    
    func testRwLockBusy() {
        var value = 1
        var running = true
        let lock = RwLock()
        let expect = XCTestExpectation()
        let queue = DispatchQueue.init(label: "com.mioke.test.queue1", attributes: .concurrent)
        
        queue.async {
            while running {
                lock.read {
                    print(value)
                }
            }
        }
        queue.async {
            while running {
                lock.read {
                    print(value)
                }
            }
        }
        
        DispatchQueue.global().async {
            (0..<10).forEach { index in
                lock.write {
                    value += 1
                }
                usleep(100_000)
            }
            expect.fulfill()
            running = false
        }
        
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
