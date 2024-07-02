//
//  TaskQueue.swift
//  MIOSwiftyArchitecture
//
//  Created by KelanJiang on 2024/7/2.
//

#if canImport(_Concurrency)
import Foundation
import _Concurrency

/// Run tasks one by one, FIFO.
final public class TaskQueue<Element> {
    
    @ThreadSafe
    private var array: Array<TaskItem> = []
    
    private var stream: AsyncMulticast<TaskItem> = .init()
    
    /// The running state, protected by the `array`'s lock, not thread-safe.
    private var isRunning: Bool = false
    
    struct TaskItem {
        let id: String
        let task: () async -> Element
    }
    
    /// Enqueue a task and run it immediately, the finish callback will be called as non-concurrency type.
    /// - Parameters:
    ///   - id: Task id
    ///   - task: The task you want to enqueue.
    ///   - onFinished: Finish callback closure. If the result is nil, that means the `TaskQueue` has already been
    ///   deallocated before this task is finished.
    public func addTask(id: String, _ task: @escaping () async -> Element, onFinished: @escaping (Element?) -> Void) {
        let item = enqueueTask(with: id, task: task)
        let checkInvalidSelf = checkNil(self, throwing: _Concurrency.CancellationError())
        Task { [weak self] in
            await self?.waitUntilAvailable(item: item)()
            let result = try? await checkAround(checkInvalidSelf) { await item.task() }
            onFinished(result)
        }
    }
    
    /// Enqueue a task and wait for it's result.
    /// - Parameters:
    ///   - id: Task id
    ///   - task: The task you want to enqueue.
    /// - Returns: The task's result.
    public func task(id: String, _ task: @escaping () async -> Element) async -> Element {
        let item = enqueueTask(with: id, task: task)
        // The `await`s here will capture `self` and delay the deallocation if the queue has no other owners.
        await waitUntilAvailable(item: item)()
        return await item.task()
    }
    
    /// Enqueue a task and try to run it immediately.
    /// - Parameters:
    ///   - id: Task's id
    ///   - task: The task.
    /// - Returns: The wrapped Task.
    public func enqueueTask(id: String, task: @escaping () async -> Element) -> Task<Element, Error> {
        let item = enqueueTask(with: id, task: task)
        let checkInvalidSelf = checkNil(self, throwing: _Concurrency.CancellationError())
        return .init { [weak self] in
            await self?.waitUntilAvailable(item: item)()
            return try await checkAround(checkInvalidSelf) { await item.task() }
        }
    }
    
    private func enqueueTask(with id: String, task: @escaping () async -> Element) -> TaskItem {
        let item = TaskItem(id: id, task: { [weak self] in
            let result = await task()
            if let self {
                self.isRunning = false
                self.checkNext()
            }
            return result
        })
        _array.write { array in
            array.append(item)
        }
        return item
    }
    
    private func waitUntilAvailable(item: TaskItem) -> () async -> Void {
        // weak capture `self`, otherwise if any signal is waiting, the `TaskQueue` can't be deallocated.
        return { [weak self] in
            guard let (signal, token) = self?.stream.subscribe(where: { $0.id == item.id }) else { return }
            self?.checkNext()
            // Must await here first, then the `stream` can cast the item later.
            for await _ in signal { break }
            token.unsubscribe()
        }
    }
    
    private func checkNext() {
        let next: TaskItem? = _array.write { array in
            // `isRunning` must be protected by the `write`, because this whole logic determine the `isRunning` state.
            guard isRunning == false, let next = array.first else { return nil }
            array.removeFirst()
            isRunning = true
            return next
        }
        guard let next else { return }
        
        // cast asynchrounously, make sure the `cast` is run after `await`.
        Task {
            stream.cast(next)
        }
    }
    
    deinit {
        print("deallocating ...")
    }
}

public typealias ThrowingTaskQueue<Value, E: Swift.Error> = TaskQueue<Swift.Result<Value, E>>

#endif
