//
//  ProducerQueue.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/6/16.
//

import Foundation
import RxSwift

/// For enqueue *cold signals*, start them one by one, start one after the previous one sent completed.
open class ProducerQueue<Value> {
    
    struct ProducerWrapper {
        let id: Int64
        let producer: Observable<Value>
    }
    
    struct ResultWrapper {
        let id: Int64
        let result: Swift.Result<Value, Swift.Error>
    }
    
    private let idGen: IdGenerator = .init()
    private var producers: [ProducerWrapper] = []
    private let queue: DispatchQueue = .init(label: Consts.domainPrefix + ".producerqueue", qos: .utility)
    private let cancel: DisposeBag = .init()
    private let subject: PublishSubject<ResultWrapper> = .init()
    
    private var isProcessing: Atomic<Bool> = .init(value: false)
    
    public func enqueue(producer: Observable<Value>) -> Observable<Value> {
        let id = idGen.gen()
        let producerWrapper = ProducerWrapper(id: id, producer: producer)
        check(producerWrapper)
        return subject.asObservable()
            .filter { $0.id == id }
            .flatMapLatest({ (result) -> Observable<Value> in
                switch result.result {
                case .success(let value):
                    return .just(value)
                case .failure(let error):
                    return .error(error)
                }
            })
    }
    
    private func check(_ wrapper: ProducerWrapper? = nil) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            if let wrapper = wrapper {
                self.producers.append(wrapper)
            }
            
            guard !self.isProcessing.value, let next = self.producers.first else { return }
            
            let id = next.id
            self.isProcessing.swap(true)
            self.producers.removeFirst()
            
            next.producer
            // This place shouldn't change the queue, because producer may have it's own queue and we shouldn't change
            // the expectation of users.
                .subscribe({ event in
                    var result: ResultWrapper? = nil
                    switch event {
                    case .next(let value):
                        result = ResultWrapper(id: id, result: .success(value))
                    case .error(let error):
                        result = ResultWrapper(id: id, result: .failure(error))
                        self.isProcessing.swap(false)
                        self.check()
                    case .completed:
                        self.isProcessing.swap(false)
                        self.check()
                    }
                    if let result = result {
                        self.subject.onNext(result)
                    }
                })
                .disposed(by: self.cancel)
        }
    }
    
}

class IdGenerator {
    private let _lock: UnfairLock = .init()
    private var id: Int64 = 0
    
    func gen() -> Int64 {
        _lock.lock()
        defer {
            id += 1
            _lock.unlock()
        }
        return id
    }
}
