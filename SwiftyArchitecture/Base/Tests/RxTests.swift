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
    
    func testDelayWorker() {
        let work = Observable<Int>.create { observer in
            observer.onNext(1)
            observer.onCompleted()
            return Disposables.create()
        }
        
        let expect = XCTestExpectation()
        
        DelayWorker.delay(work: work, interval: .seconds(3))
            .debug(#function + "1", trimOutput: true)
            .do(onCompleted: {
                expect.fulfill()
            })
            .subscribe()
            .disposed(by: cancel)
        
        DelayWorker.delay(work: work, interval: .microseconds(0))
            .debug(#function + "2", trimOutput: true)
            .subscribe()
            .disposed(by: cancel)
        
        wait(for: [expect], timeout: 5)
    }
}

