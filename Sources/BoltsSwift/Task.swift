/*
 *  Copyright (c) 2016, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation

enum TaskState<TResult> {
    case Pending()
    case Success(TResult)
    case Error(ErrorType)
    case Cancelled

    static func fromClosure(@noescape closure: () throws -> TResult) -> TaskState {
        do {
            return .Success(try closure())
        } catch is CancelledError {
            return .Cancelled
        } catch {
            return .Error(error)
        }
    }
}

//--------------------------------------
// MARK: - Task
//--------------------------------------

///
/// The consumer view of a Task.
/// Task has methods to inspect the state of the task, and to add continuations to be run once the task is complete.
///
public final class Task<TResult> {
    public typealias Continuation = () -> Void

    private let synchronizationQueue = dispatch_queue_create("com.bolts.task", DISPATCH_QUEUE_CONCURRENT)
    private let completedCondition = NSCondition()

    private var _state: TaskState<TResult> = .Pending()
    private var _continuations: [Continuation] = Array()

    // MARK: Initializers

    init() {}

    private init(state: TaskState<TResult>) {
        _state = state
    }

    /**
     Creates a task that is already completed with the given result.

     - parameter result: The task result.
     */
    public init(_ result: TResult) {
        _state = .Success(result)
    }

    /**
     Initializes a task that is already completed with the given error.

     - parameter error: The task error.
     */
    public init(error: ErrorType) {
        _state = .Error(error)
    }

    /**
     Creates a cancelled task.

     - returns: A cancelled task.
     */
    public class func cancelledTask() -> Self {
        // Swift prevents this method from being called `cancelled` due to the `cancelled` instance var. This is most likely a bug.
        return self.init(state: .Cancelled)
    }

    private class func emptyTask() -> Task<Void> {
        return Task<Void>(state: .Success())
    }

    // MARK: Execute

    /**
     Creates a task that will complete with the result of the given closure.

     - note: The closure cannot make the returned task to fail. Use the other `execute` overload for this.

     - parameter executor: Determines how the the closure is called. The default is to call the closure immediately.
     - parameter closure:  The closure that returns the result of the task.
     The returned task will complete when the closure completes.
     */
    public convenience init(_ executor: Executor = .Default, closure: (Void throws -> TResult)) {
        self.init(state: .Pending())
        executor.execute {
            self.trySetState(TaskState.fromClosure(closure))
        }
    }

    /**
     Creates a task that will continue with the task returned by the given closure.

     - parameter executor: Determines how the the closure is called. The default is to call the closure immediately.
     - parameter closure:  The closure that returns the continuation task.
     The returned task will complete when the continuation task completes.

     - returns: A task that will continue with the task returned by the given closure.
     */
    public class func execute(executor: Executor = .Default, closure: (Void throws -> TResult)) -> Task {
        return Task(executor, closure: closure)
    }

    /**
     Creates a task that will continue with the task returned by the given closure.

     - parameter executor: Determines how the the closure is called. The default is to call the closure immediately.
     - parameter closure:  The closure that returns the continuation task.
     The returned task will complete when the continuation task completes.

     - returns: A task that will continue with the task returned by the given closure.
     */
    public class func executeWithTask(executor: Executor = .Default, closure: (() throws -> Task)) -> Task {
        return emptyTask().continueWithTask(executor) { _ in
            return try closure()
        }
    }

    // MARK: Continuations

    /**
     Enqueues a given closure to be run once this task is complete.

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns the result of the task.

     - returns: A task that will be completed with a result from a given closure.
     */
    public func continueWith<S>(executor: Executor = .Default, continuation: (Task throws -> S)) -> Task<S> {
        return continueWithTask(executor) { task in
            let state = TaskState.fromClosure({
                try continuation(task)
            })
            return Task<S>(state: state)
        }
    }

    /**
     Enqueues a given closure to be run once this task is complete.

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    public func continueWithTask<S>(executor: Executor = .Default, continuation: (Task throws -> Task<S>)) -> Task<S> {
        let taskCompletionSource = TaskCompletionSource<S>()
        let wrapperContinuation = {
            executor.execute {
                let wrappedState = TaskState<Task<S>>.fromClosure {
                    try continuation(self)
                }
                switch wrappedState {
                case .Success(let nextTask):
                    switch nextTask.state {
                    case .Pending:
                        nextTask.continueWith { nextTask in
                            taskCompletionSource.setState(nextTask.state)
                        }
                    default:
                        taskCompletionSource.setState(nextTask.state)
                    }
                case .Error(let error):
                    taskCompletionSource.setError(error)
                case .Cancelled:
                    taskCompletionSource.cancel()
                default: abort() // This should never happen.
                }
            }
        }
        appendOrRunContinuation(wrapperContinuation)
        return taskCompletionSource.task
    }

    /**
     Enqueues a given closure to be run once this task completes with success (has intended result).

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    public func continueOnSuccessWith<S>(executor: Executor = .Default, continuation: (TResult throws -> S)) -> Task<S> {
        return continueOnSuccessWithTask(executor) { taskResult in
            let state = TaskState.fromClosure({
                try continuation(taskResult)
            })
            return Task<S>(state: state)
        }
    }

    /**
     Enqueues a given closure to be run once this task completes with success (has intended result).

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    public func continueOnSuccessWithTask<S>(executor: Executor = .Default, continuation: (TResult throws -> Task<S>)) -> Task<S> {
        return continueWithTask(executor) { task in
            switch task.state {
            case .Success(let result):
                return try continuation(result)
            case .Cancelled:
                return Task<S>.cancelledTask()
            case .Error(let error):
                return Task<S>(state: .Error(error))
            default:
                abort() // This should never happen.
            }
        }
    }

    /**
     Enqueues a given closure to be run once this task completes with error.

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    public func continueOnErrorWith<E: ErrorType>(executor: Executor = .Default, continuation: (E throws -> TResult)) -> Task {
        return continueOnErrorWithTask(executor) { (error: E) in
            let state = TaskState.fromClosure({
                try continuation(error)
            })
            return Task(state: state)
        }
    }

    /**
     Enqueues a given closure to be run once this task completes with error.

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    public func continueOnErrorWith(executor: Executor = .Default, continuation: (ErrorType throws -> TResult)) -> Task {
        return continueOnErrorWithTask(executor) { (error: ErrorType) in
            let state = TaskState.fromClosure({
                try continuation(error)
            })
            return Task(state: state)
        }
    }

    /**
     Enqueues a given closure to be run once this task completes with error.

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    public func continueOnErrorWithTask<E: ErrorType>(executor: Executor = .Default, continuation: (E throws -> Task)) -> Task {
        return continueOnErrorWithTask(executor) { (error: ErrorType) in
            if let error = error as? E {
                return try continuation(error)
            }
            return Task(state: .Error(error))
        }
    }

    /**
     Enqueues a given closure to be run once this task completes with error.

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    public func continueOnErrorWithTask(executor: Executor = .Default, continuation: (ErrorType throws -> Task)) -> Task {
        return continueWithTask(executor) { task in
            switch task.state {
            case .Success(let result):
                return Task(result)
            case .Cancelled:
                return Task.cancelledTask()
            case .Error(let error):
                return try continuation(error)
            default:
                abort() // This should never happen.
            }
        }
    }

    /**
     Waits until this operation is completed.

     This method is inefficient and consumes a thread resource while it's running.
     It should be avoided. This method logs a warning message if it is used on the main thread.
     */
    public func waitUntilCompleted() {
        if NSThread.isMainThread() {
            debugPrint("Warning: A long-running operation is being executed on the main thread waiting on \(self).")
        }
        if completed {
            return
        }
        completedCondition.lock()
        while !completed {
            completedCondition.wait()
        }
        completedCondition.unlock()
    }

    // MARK: State Accessors

    ///  Whether this task is completed. A completed task can also be faulted or cancelled.
    public var completed: Bool {
        switch state {
        case .Pending:
            return false
        default:
            return true
        }
    }

    ///  Whether this task has completed due to an error or exception. A `faulted` task is also completed.
    public var faulted: Bool {
        switch state {
        case .Error:
            return true
        default:
            return false
        }
    }

    /// Whether this task has been cancelled. A `cancelled` task is also completed.
    public var cancelled: Bool {
        switch state {
        case .Cancelled:
            return true
        default:
            return false
        }
    }

    /// The result of a successful task. Won't be set until the task completes with a `result`.
    public var result: TResult? {
        switch state {
        case .Success(let result):
            return result
        default:
            break
        }
        return nil
    }

    /// The error of a errored task. Won't be set until the task completes with `error`.
    public var error: ErrorType? {
        switch state {
        case .Error(let error):
            return error
        default:
            break
        }
        return nil
    }

    // MARK: State Change

    func trySetState(state: TaskState<TResult>) -> Bool {
        var stateChanged = false

        var continuations: [Continuation]?
        dispatch_barrier_sync(synchronizationQueue) {
            switch self._state {
            case .Pending():
                stateChanged = true
                self._state = state
                continuations = self._continuations
            default:
                break
            }
        }
        if stateChanged {
            completedCondition.lock()
            completedCondition.broadcast()
            completedCondition.unlock()

            for continuation in continuations! {
                continuation()
            }
        }

        return stateChanged
    }

    // MARK: Private

    private func appendOrRunContinuation(continuation: Continuation) {
        var runContinuation = false
        dispatch_barrier_sync(synchronizationQueue) {
            switch self._state {
            case .Pending:
                self._continuations.append(continuation)
            default:
                runContinuation = true
            }

        }
        if runContinuation {
            continuation()
        }
    }

    private var state: TaskState<TResult> {
        var value: TaskState<TResult>?
        dispatch_sync(synchronizationQueue) {
            value = self._state
        }
        return value!
    }
}

//--------------------------------------
// MARK: - Task with Delay
//--------------------------------------

extension Task {
    /**
     Creates a task that will complete after the given delay.

     - parameter delay: The delay for the task to completes.

     - returns: A task that will complete after the given delay.
     */
    public class func withDelay(delay: NSTimeInterval) -> Task<Void> {
        let taskCompletionSource = TaskCompletionSource<Void>()
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * NSTimeInterval(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            taskCompletionSource.trySetResult()
        }
        return taskCompletionSource.task
    }
}

//--------------------------------------
// MARK: - WhenAll
//--------------------------------------

extension Task {

    /**
     Creates a task that will be completed after all of the input tasks have completed.

     - parameter tasks: Array tasks to wait on for completion.

     - returns: A new task that will complete after all `tasks` are completed.
     */
    public class func whenAll(tasks: [Task]) -> Task<Void> {
        if tasks.isEmpty {
            return Task.emptyTask()
        }

        var tasksCount: Int32 = Int32(tasks.count)
        var cancelledCount: Int32 = 0
        var errorCount: Int32 = 0

        let tcs = TaskCompletionSource<Void>()
        tasks.forEach {
            $0.continueWith { task -> Void in
                if task.cancelled {
                    OSAtomicIncrement32(&cancelledCount)
                } else if task.faulted {
                    OSAtomicIncrement32(&errorCount)
                }

                if OSAtomicDecrement32(&tasksCount) == 0 {
                    if cancelledCount > 0 {
                        tcs.cancel()
                    } else if errorCount > 0 {
                        tcs.setError(AggregateError(errors: tasks.flatMap({ $0.error })))
                    } else {
                        tcs.setResult()
                    }
                }
            }
        }
        return tcs.task
    }

    /**
     Creates a task that will be completed after all of the input tasks have completed.

     - parameter tasks: Zero or more tasks to wait on for completion.

     - returns: A new task that will complete after all `tasks` are completed.
     */
    public class func whenAll(tasks: Task...) -> Task<Void> {
        return whenAll(tasks)
    }

    /**
     Creates a task that will be completed after all of the input tasks have completed.

     - parameter tasks: Array of tasks to wait on for completion.

     - returns: A new task that will complete after all `tasks` are completed.
     The result of the task is going an array of results of all tasks in the same order as they were provided.
     */
    public class func whenAllResult(tasks: [Task]) -> Task<[TResult]> {
        return whenAll(tasks).continueOnSuccessWithTask { task -> Task<[TResult]> in
            let results: [TResult] = tasks.map { task in
                guard let result = task.result else {
                    // This should never happen.
                    // If the task succeeded - there is no way result is `nil`, even in case TResult is optional,
                    // because `task.result` would have a type of `Result??`, and we unwrap only one optional here.
                    // If a task was cancelled, we should have never have gotten past 'continueOnSuccess'.
                    // If a task errored, we should have returned a 'AggregateError' and never gotten past 'continueOnSuccess'.
                    // If a task was pending, then something went horribly wrong.
                    fatalError("Task is in unknown state \(task.state).")
                }
                return result
            }
            return Task<[TResult]>(results)
        }
    }

    /**
     Creates a task that will be completed after all of the input tasks have completed.

     - parameter tasks: Zero or more tasks to wait on for completion.

     - returns: A new task that will complete after all `tasks` are completed.
     The result of the task is going an array of results of all tasks in the same order as they were provided.
     */
    public class func whenAllResult(tasks: Task...) -> Task<[TResult]> {
        return whenAllResult(tasks)
    }
}

//--------------------------------------
// MARK: - WhenAny
//--------------------------------------

extension Task {

    /**
     Creates a task that will complete when any of the input tasks have completed.

     The returned task will complete when any of the supplied tasks have completed.
     This is true even if the first task to complete ended in the canceled or faulted state.

     - parameter tasks: Array of tasks to wait on for completion.

     - returns: A new task that will complete when any of the `tasks` are completed.
     */
    public class func whenAny(tasks: [Task]) -> Task<Void> {
        if tasks.isEmpty {
            return Task.emptyTask()
        }
        let taskCompletionSource = TaskCompletionSource<Void>()
        for task in tasks {
            // Do not continue anything if we completed the task, because we fulfilled our job here.
            if taskCompletionSource.task.completed {
                break
            }
            task.continueWith { task in
                taskCompletionSource.trySetResult()
            }
        }
        return taskCompletionSource.task
    }

    /**
     Creates a task that will complete when any of the input tasks have completed.

     The returned task will complete when any of the supplied tasks have completed.
     This is true even if the first task to complete ended in the canceled or faulted state.

     - parameter tasks: Zeror or more tasks to wait on for completion.

     - returns: A new task that will complete when any of the `tasks` are completed.
     */
    public class func whenAny(tasks: Task...) -> Task<Void> {
        return whenAny(tasks)
    }
}

//--------------------------------------
// MARK: - Description
//--------------------------------------

extension Task: CustomStringConvertible, CustomDebugStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        return "Task: \(self.state)"
    }

    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        return "Task: \(self.state)"
    }
}
