//
//  RxSwift+Concurrency.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/1/31.
//

import Foundation
import RxSwift
import SwiftConcurrencySupport

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
  
  func valueStream() -> AsyncThrowingStream<Element, Swift.Error> {
    let observer = AsyncThrowingStream<Element, Swift.Error>.makeStream()
    
    let disposable = self.subscribe { element in
      observer.continuation.yield(element)
    } onError: { error in
      observer.continuation.finish(throwing: error)
    } onCompleted: {
      observer.continuation.finish()
    } onDisposed: {
      observer.continuation.finish()
    }
    
    observer.continuation.onTermination = { reason in
      disposable.dispose()
    }
    
    return observer.stream
  }
}


@available(iOS 13, *)
public extension UnsubscribeToken {
  
  /// Extern lifetime corresponding to an object.
  /// - Parameter object: An object.
  func bindLifetime(to object: AnyObject) {
    let reactive = Reactive(object)
    reactive.deallocating
      .subscribe(onNext: { [weak self] _ in
        self?.unsubscribe()
      })
      .disposed(by: reactive.lifetime)
  }
}


#endif
