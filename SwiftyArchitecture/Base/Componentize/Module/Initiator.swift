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
        
        var producer: ObservableSignal {
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
    
    /// The Task's priority
    public enum Priority: Int {
        /// Running in `didFinishLaunching` with main thread and block the prosedure.
        case high = 0
        /// Running in `didFinishLaunching` with an async global thread and block the prosedure.
        case asyncHigh
        /// Running after `didFinishLaunching` and the first frame is prepared for present.
        case afterFirstFrame
        /// Running after the `afterFirstFrame` with an async global thread with `background` qos setting.
        case low
        /// Only Running when CPU and memory usage is low
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
        guard let list = moduleManager.moduleList else { throw todo_error() }
        taskMap = list.internalModules
            .compactMap { $0.initiator() }
            .reduce(into: [Priority: [Task]](), { partialResult, type in
                partialResult[type.priority] = (partialResult[type.priority] ?? []) + [
                    Initiator.Task(id: type.identifier, dependencies: type.dependencies, operation: type.operation)
                ]
            })
        
        zipTasks(ts: taskMap?[.high], scheduler: MainScheduler.instance, id: "High")
            .flatMapLatest { [weak self] _ -> ObservableSignal in
                guard let self else { return .never() }
                return zipTasks(ts: taskMap?[.asyncHigh],
                                scheduler: ConcurrentDispatchQueueScheduler(queue: asyncHighPriorityQueue),
                                id: "Async hight")
            }
            .subscribe { [weak self] _ in
                self?.highTasksFinished.onNext(true)
            }
            .disposed(by: cancel)
    }
    
    func zipTasks(ts: [Task]?, scheduler: SchedulerType, id: String) -> ObservableSignal {
        guard let tasks = ts, !tasks.isEmpty else { return .signal }
        return self.createList(with: tasks, schedule: scheduler, id: id)
    }
    
    func createList(with tasks: [Task],
                    schedule: ImmediateSchedulerType,
                    id: String)
    -> ObservableSignal {
        let results = TaskGraphBuilder.buildGraph(with: tasks).dfsMap({ node in
            node.value.producer.subscribe(on: schedule)
        })
        return ObservableSignal.zip(results)
            .mapToSignal()
            .do(onCompleted:  {
                KitLogger.info("Level [\(id)] tasks have finished.")
            })
    }
    
    var presentedFirstPage: BehaviorSubject<Bool> = .init(value: false)
    
    public func setPresentedFirstFrame() {
        presentedFirstPage.onNext(true)
        presentedFirstPage.onCompleted()
    }
    
    func subscribePresentAction() {
        Observable.zip(highTasksFinished, presentedFirstPage)
            .filter { $0.0 && $0.1 }
            .take(1)
            .mapToSignal()
            .flatMapLatest(startAfterPresentedTasks)
            .subscribe()
            .disposed(by: cancel)
    }
    
    func startAfterPresentedTasks() -> ObservableSignal {
        guard let afterFirstPage = taskMap?[.afterFirstFrame] else { return .never() }
        return createList(with: afterFirstPage,
                          schedule: ConcurrentDispatchQueueScheduler(queue: asyncHighPriorityQueue),
                          id: "After first page present")
        .flatMapLatest({ [weak self] _ -> ObservableSignal in
            guard let self, let low = self.taskMap?[.low] else { return .signal }
            return createList(
                with: low,
                schedule: ConcurrentDispatchQueueScheduler(queue: lowPriorityQueue),
                id: "Low")
        })
    }
}

extension Module {
    func initiator() -> ModuleInitiatorProtocol.Type? {
        return (Bundle.main.classNamed(className) ?? NSClassFromString(className)) as? ModuleInitiatorProtocol.Type
    }
}


extension Observable where Element == Void {
    static func create(operation: @escaping Initiator.Operation) -> ObservableSignal {
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
    
    static func add(
        task: Initiator.Task,
        visited: inout Set<Initiator.Task>,
        existing: inout [String: DirectedGraphNode<Initiator.Task>],
        tasks: [Initiator.Task])
    -> DirectedGraphNode<Initiator.Task> {
        
        let newNode = DirectedGraphNode<Initiator.Task>.init(value: task)
        existing[task.identifier] = newNode
        visited.update(with: task)
        
        if task.dependencies.count > 0 {
            let dependentNodes = task.dependencies.compactMap { id -> DirectedGraphNode<Initiator.Task>? in
                if let exist = existing[id] {
                    return exist
                } else {
                    guard let find = tasks.first(where: { $0.identifier == id }) else {
                        KitLogger.error("Error!")
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
