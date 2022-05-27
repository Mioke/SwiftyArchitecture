//
//  RxExtension.swift
//  SAD
//
//  Created by jiangkelan on 16/10/2017.
//  Copyright © 2017 KleinMioke. All rights reserved.
//

import Foundation
import RxSwift

extension Reactive  {
    public func loadData<T: ApiInfoProtocol>(with params: [String: Any]?)
        -> Observable<T.ResultType> where Base: API<T> {
        return Observable.create { observer in
            self.base.loadData(with: params).response({ (api, data, error) in
                if let error = error {
                    observer.onError(error)
                }
                else if let data = data {
                    observer.on(.next(data))
                    observer.onCompleted()
                }
            })
            return Disposables.create(with: self.base.cancel)
        }
    }
}

extension BehaviorSubject {
    public var value: Element? {
        return try? value()
    }
}
