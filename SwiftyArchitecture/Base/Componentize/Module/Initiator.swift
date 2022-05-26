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
    
    var taskMap: [Priority: [Initiator.Task]]?
    
    var highTasksFinished: BehaviorSubject<Bool> = .init(value: false)
    private let cancel: DisposeBag = .init()
    
    public func start() throws -> Void {
        guard let list = moduleManager.moduleList else {
            throw todo_error()
        }
        taskMap = list.internalModules
            .compactMap { $0.initiator() }
            .reduce(into: [Priority: [Task]](), { partialResult, type in
                partialResult[type.priority] = partialResult[type.priority] ?? []
                + [Initiator.Task(id: type.identifier, dependencies: type.dependencies, operation: type.operation)]
            })
        
        let zipTasks = { (ts: [Task]?, scheduler: SchedulerType, id: String) -> Observable<Void> in
            guard let tasks = ts else { return .just(()) }
            return self.createList(with: tasks, schedule: scheduler, id: id)
        }
        
        zipTasks(taskMap?[.high], MainScheduler.instance, "High")
            .flatMapLatest { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .never() }
                return zipTasks(self.taskMap?[.asyncHigh],
                                ConcurrentDispatchQueueScheduler(queue: self.asyncHighPriorityQueue),
                                "Async hight")
            }
            .subscribe { [weak self] _ in
                self?.highTasksFinished.onNext(true)
            }
            .disposed(by: cancel)
    }
    
    func createList(with tasks: [Task],
                    schedule: ImmediateSchedulerType,
                    id: String)
    -> Observable<Void> {
        let results = TaskGraphBuilder.buildGraph(with: tasks).dfsMap({ node in
            node.value.producer.subscribe(on: schedule)
        })
        return Observable<Void>.zip(results)
            .map { _ in () }
            .do(onCompleted:  {
                print("Level [\(id)] tasks have finished.")
            })
    }
    
    var presentedFirstPage: BehaviorSubject<Bool> = .init(value: false)
    
    public func setPresentedFirstPage() {
        presentedFirstPage.onNext(true)
        presentedFirstPage.onCompleted()
    }
    
    func subscribePresentAction() {
        Observable.zip(highTasksFinished, presentedFirstPage)
            .take(1)
            .filter { $0.0 && $0.1 }
            .subscribe { [weak self] _ in
                self?.startAfterPresentedTasks()
            }
            .disposed(by: cancel)
    }
    
    func startAfterPresentedTasks() {
        guard let afterFirstPage = taskMap?[.afterFirstPage] else { return }
        createList(with: afterFirstPage,
                   schedule: ConcurrentDispatchQueueScheduler(queue: asyncHighPriorityQueue),
                   id: "After first page present")
            .flatMapLatest({ [weak self] _ -> Observable<Void> in
                guard let self = self, let low = self.taskMap?[.low] else { return .just(()) }
                return self.createList(
                    with: low,
                    schedule: ConcurrentDispatchQueueScheduler(queue: self.lowPriorityQueue),
                    id: "Low")
            })
            .subscribe { _ in }
            .disposed(by: cancel)
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

extension Initiator.Task: Hashable {
    func hash(into hasher: inout Hasher) {
        self.identifier.hash(into: &hasher)
    }
}

class TaskGraphBuilder {
    
    static func buildGraph(with tasks: [Initiator.Task]) -> DirectedGraph<Initiator.Task> {
        var nodes: [String: DirectedGraphNode<Initiator.Task>] = [:]
        var visited: Set<Initiator.Task> = []
        
        while let pickone = tasks.filter({ !visited.contains($0) }).first {
            let _ = add(task: pickone, visited: &visited, existing: &nodes, tasks: tasks)
        }
        
        return .init(nodes: .init(nodes.values))
    }
    
    static func add(task: Initiator.Task,
                    visited: inout Set<Initiator.Task>,
                    existing: inout [String: DirectedGraphNode<Initiator.Task>],
                    tasks: [Initiator.Task])
    -> DirectedGraphNode<Initiator.Task> {
        
        let newNode = DirectedGraphNode<Initiator.Task>.init(value: task)
        existing[task.identifier] = newNode
        visited.update(with: task)
        
        if let dependencies = task.afterItems, dependencies.count > 0 {
            let dependentNodes = dependencies.compactMap { id -> DirectedGraphNode<Initiator.Task>? in
                if let exist = existing[id] {
                    return exist
                } else {
                    guard let find = tasks.first(where: { $0.identifier == id }) else {
                        print("Error!")
                        return nil
                    }
                    return add(task: find, visited: &visited, existing: &existing, tasks: tasks)
                }
            }
            newNode.out = .init(dependentNodes)
            dependentNodes.forEach { node in
                node.in.update(with: newNode)
            }
        }
        return newNode
    }
    
}
