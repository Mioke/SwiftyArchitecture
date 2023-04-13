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
    func rxSendRequest(with params: T.RequestParam?) -> Observable<T.ResultType> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            self.sendRequest(with: params).response({ (api, data, error) in
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

public extension BehaviorSubject {
    var value: Element? {
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
    
    func then<T>(_ function: @escaping (Element) -> Observable<T>) -> Observable<T> {
        return flatMapLatest(function)
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

public extension AnyObserver where Element == Void {
    func signal() -> Void {
        self.onNext(())
    }
}

public extension Reactive {
    
    var lifetime: DisposeBag {
        guard let disposeBag = objc_getAssociatedObject(self.base, #function) as? DisposeBag else {
            let disposeBag = DisposeBag.init()
            objc_setAssociatedObject(self.base, #function, disposeBag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return disposeBag
        }
        return disposeBag
    }
}
