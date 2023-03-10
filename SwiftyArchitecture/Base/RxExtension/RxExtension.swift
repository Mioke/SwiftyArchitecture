//
//  RxExtension.swift
//  SAD
//
//  Created by jiangkelan on 16/10/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import Foundation
import RxSwift

public extension API {
    func rxLoadData(with params: [String: Any]?) -> Observable<T.ResultType> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            self.loadData(with: params).response({ (api, data, error) in
                if let error = error {
                    observer.onError(error)
                }
                else if let data = data {
                    observer.on(.next(data))
                    observer.onCompleted()
                }
            })
            return Disposables.create(with: self.cancel)
        }
    }
}

extension BehaviorSubject {
    public var value: Element? {
        return try? value()
    }
}

public extension Observable {
    func mapToSignal() -> ObservableSignal {
        return self.map { _ in () }
    }
    
    func then<T>(_ observale: Observable<T>) -> Observable<T> {
        return self.flatMapLatest { _ -> Observable<T> in
            return observale
        }
    }
}

/// When Observable's value is just a signal without usable value, we can just call it `ObservableSignal`.
public typealias ObservableSignal = Observable<Void>

public extension ObservableSignal {
    /// Send a signal with meaning `success`,`ok`,`notify` etc., a wrapper of `.just(())` and make it more readable.
    static var signal: ObservableSignal { .just(()) }
}

extension Observable {
    static var deallocatedError: Observable<Element> {
        return .error(KitErrors.deallocated)
    }
}
