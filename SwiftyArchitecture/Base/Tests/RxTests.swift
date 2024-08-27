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
    
    let ob1 = Single<Int>.create { observer in
      observer(.success(0))
      return Disposables.create()
    }
    
    let ob2 = Single<Int>.create { observer in
      observer(.success(1))
      return Disposables.create()
    }
    
    var results: [Int] = []
    queue.enqueue(single:  ob1)
      .subscribe(onNext: { value in
        print(value)
        results.append(value)
      })
      .disposed(by: cancel)

    queue.enqueue(single: ob2)
      .subscribe { value in
        print(value)
        results.append(value)
        XCTAssert(results == [0, 1])
        expect.fulfill()
      }
      .disposed(by: cancel)
    
    wait(for: [expect], timeout: 2)
  }
  
}

