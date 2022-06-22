//
//  DelayWorker.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/6/22.
//

import UIKit
import RxSwift

public class DelayWorker {
    
    public enum Event<T> {
        case skip
        case value(Swift.Result<T, Swift.Error>)
    }
    
    public static func delay<T>(
        work: Observable<T>,
        interval: DispatchTimeInterval,
        onQueue: DispatchQueue = .global())
    -> Observable<Event<T>> {
        return .create { observer in
            let worker = { () -> Disposable in
                return work.subscribe { rst in
                    observer.onNext(.value(.success(rst)))
                } onError: { error in
                    observer.onNext(.value(.failure(error)))
                } onCompleted: {
                    observer.onCompleted()
                }
            }
            
            if interval == .seconds(0) {
                // run this worker synchronizely.
                return worker()
            } else {
                observer.onNext(.skip)
                let disposable = CompositeDisposable.init()
                DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
                    _ = disposable.insert(worker())
                }
                return disposable
            }
        }
    }
    
}
