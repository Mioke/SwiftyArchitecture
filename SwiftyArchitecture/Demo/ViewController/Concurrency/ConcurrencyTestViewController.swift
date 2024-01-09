//
//  ConcurrencyTestViewController.swift
//  SAD
//
//  Created by KelanJiang on 2023/6/12.
//  Copyright © 2023 KleinMioke. All rights reserved.
//

import UIKit
import MIOSwiftyArchitecture
import _Concurrency
import RxSwift

class ConcurrencyTestViewController: UIViewController {
    
    var streamContinuation: AsyncThrowingStream<Int, any Error>.Continuation?
    lazy var stream: AsyncThrowingStream<Int, any Error> = .init { continuation in
        streamContinuation = continuation
    }
    
    let signalStream: AsyncThrowingSignalStream<Int> = .init()
    
    enum State {
        case one
        case two
        case three
    }
    
    var state: BehaviorSubject<State> = .init(value: .one)
    
    let intSignals: Observable<Int> = .from([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])
    var currentSignal: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
//        Task {
//            do {
//                async let result = timeoutTask(with: 3_000_000_000) {
//                    try await Task.sleep(nanoseconds: 5_000_000_000)
//                    return "ahhhhh"
//                } onTimeout: {
//                    print("timeout!")
//                }
//                print(try await result)
//            } catch {
//                print(error)
//            }
//
//            _ = stream
//
//            streamContinuation?.onTermination = { termination in
//                if case AsyncThrowingStream<Int, any Error>.Continuation.Termination.finished(let error) = termination {
//                    print(error, "$$$")
//                }
//            }
//
//        }
        
//        Task {
//            let rst = try await self.signalStream.wait { value in
//                value == 10
//            }
//            print("have waited for \(rst)")
//        }
//
//        Task {
//            let rst = try await self.signalStream.wait { value in
//                value == 5
//            }
//            print("have waited for \(rst)")
//        }
//
//        Task.detached {
//            for i in 0...10 {
//                try await self.signalStream.send(signal: i)
//                try await Task.sleep(nanoseconds: 500_000_000)
//            }
//        }
        
//        FeatureManager.shared.updateToggleValue()
        
        Task {
            intSignals
                .subscribe(on: SerialDispatchQueueScheduler.init(qos: .default)) // effective
                .subscribe(onNext: { value in
                    Task.detached { [weak self] in
                        print("before task", value, Thread.current, Thread.isMainThread)
                        await self?.updateCurrentSignal(with: value)
                    }
                })
                .disposed(by: self.rx.lifetime)
            
//            for try await value in intSignals.subscribe(on: SerialDispatchQueueScheduler.init(qos: .default)).values {
//                print(value, Thread.current, Thread.isMainThread)
//            }
        }
        
        if #available(iOS 16, *) {
            
            self.state
                .subscribe { event in
                    print("VC Thread:", Thread.current)
                }
                .disposed(by: self.rx.lifetime)
            
            Task {
                _ = try await FeatureManager.shared.asyncUpdateToggleValue() // switch to cooperative thread.
                self.state.onNext(.two) // switch back to main thread.
            }
            
            Task {
                _ = try await FeatureManager.shared.asyncUpdateToggleValueMain()
                self.state.onNext(.two) //
            }
        }
    }
    
    func updateCurrentSignal(with value: Int) async -> Void {
        self.currentSignal = value
        print(value, Thread.current, Thread.isMainThread)
    }

}

class FeatureManager: NSObject {
    static let shared: FeatureManager = .init()
    let toggle: BehaviorSubject<Bool> = .init(value: false)
    let privateActor: FeatureManagerActor = .init()
    
    override init() {
        super.init()
        toggle.subscribe { event in
            print("Thread:", Thread.current)
        }
        .disposed(by: self.rx.lifetime)
    }
    
    func updateToggleValue() -> Void {
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(2)) {
            self.toggle.onNext(true)
        }
    }
    
    @available(iOS 16.0, *)
    func asyncUpdateToggleValue() async throws -> Bool {
        try await Task.sleep(for: .seconds(5))
        toggle.onNext(true)
        return true
    }
    
    @available(iOS 16.0, *)
    func asyncUpdateToggleValueMain() async throws -> Bool {
        try await Task.sleep(for: .seconds(5))
        DispatchQueue.main.async { // effective and won't get dead lock.
            self.toggle.onNext(true)
        }
        return true
    }
    
    func foo() async {
        let result = try! await privateActor.invoke { actor in
            try await Task.sleep(nanoseconds: 100)
            return true
        }
        
        MainActor.async {
            
        }
        
        _ = await MainActor.run {
            return 1
        }
        
        Task(priority: .high) {
            
        }
        
        
    }
}

actor FeatureManagerActor: Actor { }

