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
import SwiftConcurrencySupport

class ConcurrencyTestViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let (stream, continuation) = AsyncThrowingStream<Int, any Error>.makeStream()
    
    let signalStream: AsyncThrowingSignalStream<Int> = .init()
    
    enum State {
        case one
        case two
        case three
    }
    
    var state: BehaviorSubject<State> = .init(value: .one)
    
    let intSignals: Observable<Int> = .from([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])
    var currentSignal: Int = 0
    
    let tableView: UITableView = .init(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        view.addSubview(tableView)
        tableView.backgroundColor = .gray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ])
        
        tableView.reloadData()
        
//        let caster = stream.makeMulticaster()
//        
//        Task {
//            let observer = caster.multicaster.subscribe()
//            for try await value in observer.stream {
//                print("+" , value)
//            }
//        }
//        
//        Task {
//            try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
//            caster.multicaster.cast(1)
//            try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
//            continuation.yield(2)
//        }
//        
        // Can't await more than once.
        
//        Task.detached {
//            var iterator = self.stream.makeAsyncIterator()
//            while let value = try await iterator.next() {
//                print(value)
//            }
//        }
//        
//        Task.detached {
//            var iterator = self.stream.makeAsyncIterator()
//            while let value = try await iterator.next() {
//                print(value)
//            }
//        }
//        
//        Task.detached(weakCapturing: self) { me in
//            try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
//            me.continuation.yield(1)
//            me.continuation.yield(2)
//        }
        
//        Task {
//            do {
//                async let result = timeoutTask(with: 2 * Consts.nanosecondsPerSecond) {
//                    try await Task.sleep(nanoseconds: 5 * Consts.nanosecondsPerSecond)
//                    return "ahhhhh"
//                } onTimeout: {
//                    print("timeout!")
//                }
//                print(try await result)
//            } catch {
//                print(error)
//            }
//
////            _ = stream
////
////            streamContinuation?.onTermination = { termination in
////                if case AsyncThrowingStream<Int, any Error>.Continuation.Termination.finished(let error) = termination {
////                    print(error, "$$$")
////                }
////            }
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
        
//        Task {
//            intSignals
//                .subscribe(on: SerialDispatchQueueScheduler.init(qos: .default)) // effective
//                .subscribe(onNext: { value in
//                    Task.detached { [weak self] in
//                        print("before task", value, Thread.current, Thread.isMainThread)
//                        await self?.updateCurrentSignal(with: value)
//                    }
//                })
//                .disposed(by: self.rx.lifetime)
//            
////            for try await value in intSignals.subscribe(on: SerialDispatchQueueScheduler.init(qos: .default)).values {
////                print(value, Thread.current, Thread.isMainThread)
////            }
//        }
        
        if #available(iOS 16, *) {
            
//            self.state
//                .subscribe { event in
//                    print("# get event: \(event)", "Thread:", Thread.current)
//                }
//                .disposed(by: self.rx.lifetime)
//            
//            Task {
//                printThreadInfo(prefix: "1.")
//                _ = try await FeatureManager.shared.asyncUpdateToggleValue() // switch to cooperative thread.
//                self.state.onNext(.two) // switch back to main thread.
//            }
//            
//            Task {
//                _ = try await FeatureManager.shared.asyncUpdateToggleValueMain()
//                self.state.onNext(.two) //
//            }
            
//            Task.detached {
//                for i in 0..<100 {
//                    await FeatureManager.shared.updateCache(value: 2 * i)
//                }
//            }
//            
//            Task.detached {
//                for i in 0..<100 {
//                    await FeatureManager.shared.updateCache(value: 2 * i + 1)
//                }
//                
//                try await Task.sleep(for: .seconds(1))
//                
//                print(FeatureManager.shared.cache)
//            }
            
            // Is task runs immediately?
            
            Task {
                let task = Task {
                    print("Enter A - \(Date().timeIntervalSince1970)")
                    try await Task.sleep(for: .seconds(1))
                    print("after sleep A - \(Date().timeIntervalSince1970)")
                    return 1
                }
                
                try await Task.sleep(for: .seconds(2))
                
                print(try await task.value, Date().timeIntervalSince1970)
            }
            
            
        }
        
    }
    
    func updateCurrentSignal(with value: Int) async -> Void {
        self.currentSignal = value
        print(value)
        printThreadInfo()
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell - \(indexPath.row)")
        ?? UITableViewCell(style: .default, reuseIdentifier: "Cell - \(indexPath.row)")
        
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
    

}


func printThreadInfo(prefix: String = "", function: String = #function, line: Int = #line) {
    print("[\(function):\(line)]", prefix, Thread.current, Thread.isMainThread)
}

@available(iOS 16.0, *)
class FeatureManager: NSObject {
    static let shared: FeatureManager = .init()
    let toggle: BehaviorSubject<Bool> = .init(value: false)
    let state: PrivateState = .init()
    
    var cache: [Int] = [] {
        didSet {
            print("###", cache.count)
        }
    }
    
    actor PrivateState : Actor {
        
    }
    
    override init() {
        super.init()
        toggle.subscribe { event in
            print("FeatureManager toggle changes: Thread:", Thread.current)
        }
        .disposed(by: self.rx.lifetime)
    }
    
    func asyncUpdateToggleValue() async throws -> Bool {
        printThreadInfo(prefix: "2.")
        for _ in 0...100000 { }
        toggle.onNext(true)
        return true
    }
    
    func asyncUpdateToggleValueMain() async throws -> Bool {
        printThreadInfo(prefix: "3.1")
        return try await state.invoke { actor in
            printThreadInfo(prefix: "3.2")
            try await Task.sleep(for: .seconds(5))
            MainActor.async {
                self.toggle.onNext(true)
            }
            return true
        }
    }
    
    func updateCacheNoProtect(value: Int) {
        cache.append(value)
    }
    
    func updateCache(value: Int) {
        // Not good, the running order will be too random. for example, run 1, 2 before into the invoke, actually
        // result can be 2, 1
        state.invoke {
            self.cache.append(value)
        }
    }
    
    func updateCache(value: Int) async {
        // Too perfect like a dream !?!?
        // [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199]
        await state.invoke { _ in
            self.cache.append(value)
        }
    }
    
}

