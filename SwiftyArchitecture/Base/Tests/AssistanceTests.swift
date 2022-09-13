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
            (0..<1000).forEach { index in
                lock.write {
                    value += 1
                }
            }
            expect.fulfill()
            running = false
        }
        
        wait(for: [expect], timeout: 5)
    }
    
    @ThreadSafe
    var value: Int = 1
    
    func testAtomicBusy2() {
        var running = true
        let expect = XCTestExpectation()
        let queue = DispatchQueue.init(label: "com.mioke.test.queue1", attributes: .concurrent)
        
        queue.async {
            while running {
                print(self.value)
            }
        }
        queue.async {
            while running {
                print(self.value)
            }
        }
        
        DispatchQueue.global().async {
            (0..<100).forEach { index in
                self.value += 1
                usleep(10_000)
            }
            expect.fulfill()
            running = false
        }
        
        wait(for: [expect], timeout: 5)
    }
    
    @ThreadSafe
    var dic: Dictionary<String, Int> = [:]

    @ThreadSafe
    var array: Array<Int> = []
    
    @ThreadSafe
    var string: String = ""
    
    func testAtomicBusy3() {
        var running = true
        let expect = XCTestExpectation()
        let queue = DispatchQueue.init(label: "com.mioke.test.queue1", attributes: .concurrent)
        self.dic.updateValue(1, forKey: "key")
        self.dic.updateValue(1, forKey: "key2")
        self.dic.updateValue(1, forKey: "key3")
        self.dic.updateValue(1, forKey: "key4")
        self.dic.updateValue(1, forKey: "key5")
        
        queue.async {
            while running {
//                self.array.append(1)
//                self.array.removeFirst()
                
//                self.string = "1"
//
//                var origin = self.dic
//                origin["key"] = 1
//                self.dic = origin
                
                self.dic["key"] = 1
                
//                self.dic.updateValue(1, forKey: "key")
            }
        }
        queue.async {
            while running {
//                self.array.append(1)
//                self.array.removeFirst()
                
//                self.value = 1
                
//                self.string = "1"

//                var origin = self.dic
//                origin["key"] = 1
//                self.dic = origin
                
                self.dic["key3"] = 1
                
//                self.dic.updateValue(1, forKey: "key")
            }
        }
        
        queue.async {
            while running {
                self.dic.forEach { print($0) }
            }
        }
        
        DispatchQueue.global().async {
            (0..<1000).forEach { index in
//                self.value += 1
                usleep(10_000)
            }
            expect.fulfill()
            running = false
        }
        
        wait(for: [expect], timeout: 60)
    }
    
    @ThreadSafe
    var dic2: [Int: Int] = [:]
    
    func testAtomicBusy4() {
        let expect = XCTestExpectation()
        let queue = DispatchQueue.init(label: "com.mioke.test.queue1", attributes: .concurrent)
        
        let group = DispatchGroup.init()
        
        group.enter()
        queue.async {
            for i in 0..<100 {
                self.dic2[i] = i
            }
            group.leave()
        }
        
        group.enter()
        queue.async {
            for i in 100..<200 {
                self.dic2[i] = i
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            print(self.dic2.count)
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 60)
    }
    
    func testAtomicContainer() {
        let expect = XCTestExpectation()
        let queue = DispatchQueue.init(label: "com.mioke.test.queue1", attributes: .concurrent)
        
        let atodic: Atomic<[Int: Int]> = .init(value: [:])
        let group = DispatchGroup.init()
        
        atodic.modify { value in
            value[0] = 1
        }
        
        group.enter()
        queue.async {
            for i in 0..<100 {
                atodic.modify { value in
                    value[i] = i
                }
            }
            group.leave()
        }
        
        group.enter()
        queue.async {
            for i in 100..<200 {
                atodic.modify { value in
                    value[i] = i
                }
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            XCTAssertTrue(atodic.value.count == 200, "Atomic container should be atomically changed.")
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 60)
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
    
    func testRwQueuePerformance() {
        let metirc = XCTClockMetric.init()
        measure(metrics: [metirc]) {
            let queue = RwQueue(qos: .default)
            for i in 0...100000 {
                queue.syncRead {
                    print(i)
                }
            }
        }
    }
    
    func testRwQueuePerformanceWrite() {
        let metirc = XCTClockMetric.init()
        measure(metrics: [metirc]) {
            let queue = RwQueue(qos: .default)
            for i in 0...100000 {
                queue.syncWrite {
                    print(i)
                }
            }
        }
    }
    
    func testRwLockPerformanceRead() {
        let metirc = XCTClockMetric.init()
        measure(metrics: [metirc]) {
            let lock = RwLock.init()
            for i in 0...100000 {
                lock.read {
                    print(i)
                }
            }
        }
    }
    
    func testRwLockPerformanceWrite() {
        let metirc = XCTClockMetric.init()
        measure(metrics: [metirc]) {
            let lock = RwLock.init()
            for i in 0...100000 {
                lock.write {
                    print(i)
                }
            }
        }
    }
  
}
