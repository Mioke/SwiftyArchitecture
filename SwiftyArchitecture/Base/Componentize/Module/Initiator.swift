//
//  Initiator.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2022/2/22.
//

import Foundation
import RxSwift

public protocol ModuleInitiatorProtocol {
    static var identifier: String { get }
    static var operation: Initiator.Operation { get }
    static var priority: Initiator.Priority { get }
    static var dependencies: [String] { get }
}

final public class Initiator {
    public typealias Operation = () -> Void
    
    class Task: Equatable {
        private let operation: Operation
        let identifier: String
        let dependencies: [String]
        
        var producer: Observable<Void> {
            return .create(operation: self.operation)
        }
        init(id: String, dependencies: [String], operation: @escaping Operation) {
            self.identifier = id
            self.dependencies = dependencies
            self.operation = operation
        }
        static func == (lhs: Initiator.Task, rhs: Initiator.Task) -> Bool {
            return lhs.identifier == rhs.identifier
        }
    }
    
    public enum Priority: Int {
        case high = 0
        case asyncHigh
        case afterFirstPage
        case low
        case idle
    }
    
    static var tasks: [Initiator.Task] = []
    
    lazy var asyncHighPriorityQueue: DispatchQueue = .global(qos: .userInitiated)
    lazy var lowPriorityQueue: DispatchQueue = .global(qos: .unspecified)
    lazy var idlePriorityQueue: DispatchQueue = .global(qos: .background)
    
    let moduleManager: ModuleManager
    
    init(moduleManager: ModuleManager) {
        self.moduleManager = moduleManager
    }
    
    private let bag: DisposeBag = .init()
    
    public func start() throws -> Void {
        guard let list = moduleManager.moduleList else {
            throw todo_error()
        }
        let taskMap = list.internalModules
            .compactMap { $0.initiator() }
            .reduce(into: [Priority: [Task]](), { partialResult, type in
                partialResult[type.priority] = partialResult[type.priority] ?? []
                + [Initiator.Task(id: type.identifier, dependencies: type.dependencies, operation: type.operation)]
            })
        
        Observable.just(taskMap[.high])
            .flatMapLatest { tasks -> Observable<Void> in
                guard let tasks = tasks else { return .just(()) }
                return self.createList(with: tasks, schedule: MainScheduler.instance)
            }
            .flatMapLatest { _ in
                return Observable.just(taskMap[.asyncHigh])
                    .flatMapLatest { tasks -> Observable<Void> in
                        guard let tasks = tasks else { return .just(()) }
                        return self.createList(with: tasks, schedule: ConcurrentDispatchQueueScheduler.init(queue: self.asyncHighPriorityQueue))
                    }
            }
            .subscribe { _ in
                print("high and async high is finished")
            } onError: { e in
                print("high and async high is interrupted by \(e)")
            } onCompleted: {
                print("high and async high is completed")
            } onDisposed: {
                print("high and async high is disposed")
            }
            .disposed(by: bag)
    }
    
    func createList(with tasks: [Task], schedule: ImmediateSchedulerType) -> Observable<Void> {
        let list = InitiatorList(tasks: tasks)
        var results: [Observable<Void>] = []
        list.forEach { results.append($0.producer.subscribe(on: schedule)) }
        return Observable<Void>.merge(results)
    }
}

extension Module {
    func initiator() -> ModuleInitiatorProtocol.Type? {
        return (Bundle.main.classNamed(className) ?? NSClassFromString(className)) as? ModuleInitiatorProtocol.Type
    }
}


extension Observable where Element == Void {
    static func create(operation: @escaping Initiator.Operation) -> Observable<Void> {
        return .create { ob in
            operation()
            ob.onNext(())
            ob.onCompleted()
            return Disposables.create()
        }
    }
}
