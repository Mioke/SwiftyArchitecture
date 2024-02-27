//
//  RxSwift+Concurrency.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/1/31.
//

import Foundation
import RxSwift

#if canImport(_Concurrency)

public extension Observable {
    
    /// Create an Observable using a concurrency task.
    /// - Parameter op: The concurrency task closure.
    @available(iOS 13, *)
    static func task(_ op: @Sendable @escaping () async throws -> Element) -> Observable<Element> {
        return Self.create { ob -> Disposable in
            let task = Task {
                do {
                    ob.onNext(try await op())
                    ob.onCompleted()
                } catch {
                    ob.onError(error)
                }
            }
            return Disposables.create {
                task.cancel()
            }
        }
    }
}

#endif
