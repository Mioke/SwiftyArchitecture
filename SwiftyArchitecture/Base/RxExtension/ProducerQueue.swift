//
//  ProducerQueue.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/6/16.
//

import Foundation
import RxSwift

/// Enqueue *cold signals*, start them one by one, start one after the previous one sent completed.
open class ProducerQueue<Value> {
  
  struct ProducerWrapper {
    let id: Int64
    let single: Single<Value>
  }
  
  struct ResultWrapper {
    let id: Int64
    let result: Swift.Result<Value, Swift.Error>
  }
  
  private let idGen: IdGenerator = .init()
  private var producers: [ProducerWrapper] = []
  private let queue: DispatchQueue
  private let cancel: DisposeBag = .init()
  private let subject: ReplaySubject<ResultWrapper> = .create(bufferSize: 1)
  
  private var isProcessing: Atomic<Bool> = .init(value: false)
  
  public init(qos: DispatchQoS = .default) {
    self.queue = .init(label: Consts.domainPrefix + ".producerqueue", qos: qos)
  }
  
  
  public func enqueue(single: Single<Value>) -> Observable<Value> {
    let id = idGen.gen()
    let producerWrapper = ProducerWrapper(id: id, single: single)
    return .create { [weak self] observer in
      guard let self else { return Disposables.create() }
      
      print("creating \(id)")
      check(producerWrapper)
      
      return subject.asObservable()
        .filter {
          print("filtering \($0.id) self \(id)")
          return $0.id == id
        }
        .subscribe { wrapper in
          switch wrapper.result {
          case .success(let value):
            observer.onNext(value)
            observer.onCompleted()
          case .failure(let error):
            observer.onError(error)
          }
        } onError: { error in
          observer.onError(error)
        } onCompleted: {
          observer.onCompleted()
        }
    }
  }
  
  private func check(_ wrapper: ProducerWrapper? = nil) {
    queue.async { [weak self] in
      guard let self else { return }
      if let wrapper = wrapper {
        producers.append(wrapper)
      }
      
      guard !isProcessing.value, let next = producers.first else { return }
      
      let id = next.id
      isProcessing.swap(true)
      producers.removeFirst()
      print("processing \(id)")
      next.single
      // This place shouldn't change the queue, because producer may have it's own queue and we shouldn't change
      // the expectation of users.
        .subscribe { [weak self] event in
          guard let self else { return }
          let result = ResultWrapper(id: id, result: event)
          isProcessing.swap(false)
          print("next \(id)")
          subject.onNext(result)
          check()
        }
        .disposed(by: cancel)
    }
  }
  
}

class IdGenerator {
  private let _lock: UnfairLock = .init()
  private var id: Int64 = 0
  
  func gen() -> Int64 {
    _lock.lock()
    defer {
      if id == Int64.max {
        id = Int64.min
      } else {
        id += 1
      }
      _lock.unlock()
    }
    return id
  }
}
