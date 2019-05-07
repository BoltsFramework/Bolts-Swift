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
    case pending
    case success(TResult)
    case error(Error)
    case cancelled

    static func fromClosure(_ closure: () throws -> TResult) -> TaskState {
        do {
            return .success(try closure())
        } catch is CancelledError {
            return .cancelled
        } catch {
            return .error(error)
        }
    }
}

struct TaskContinuationOptions: OptionSet {
    let rawValue: Int
    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let RunOnSuccess = TaskContinuationOptions(rawValue: 1 << 0)
    static let RunOnError = TaskContinuationOptions(rawValue: 1 << 1)
    static let RunOnCancelled = TaskContinuationOptions(rawValue: 1 << 2)

    static let RunAlways: TaskContinuationOptions = [ .RunOnSuccess, .RunOnError, .RunOnCancelled ]
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

    fileprivate let synchronizationQueue = DispatchQueue(label: "com.bolts.task", attributes: DispatchQueue.Attributes.concurrent)
    fileprivate var _completedCondition: NSCondition?

    fileprivate var _state: TaskState<TResult> = .pending
    fileprivate var _continuations: [Continuation] = Array()

    // MARK: Initializers

    init() {}

    init(state: TaskState<TResult>) {
        _state = state
    }

    /**
     Creates a task that is already completed with the given result.

     - parameter result: The task result.
     */
    public init(_ result: TResult) {
        _state = .success(result)
    }

    /**
     Initializes a task that is already completed with the given error.

     - parameter error: The task error.
     */
    public init(error: Error) {
        _state = .error(error)
    }

    /**
     Creates a cancelled task.

     - returns: A cancelled task.
     */
    public class func cancelledTask() -> Self {
        // Swift prevents this method from being called `cancelled` due to the `cancelled` instance var. This is most likely a bug.
        return self.init(state: .cancelled)
    }

    class func emptyTask() -> Task<Void> {
        return Task<Void>(state: .success(()))
    }

    // MARK: Execute

    /**
     Creates a task that will complete with the result of the given closure.

     - note: The closure cannot make the returned task to fail. Use the other `execute` overload for this.

     - parameter executor: Determines how the the closure is called. The default is to call the closure immediately.
     - parameter closure:  The closure that returns the result of the task.
     The returned task will complete when the closure completes.
     */
    public convenience init(_ executor: Executor = .default, closure: @escaping (() throws -> TResult)) {
        self.init(state: .pending)
        executor.execute {
            self.trySet(state: TaskState.fromClosure(closure))
        }
    }

    /**
     Creates a task that will continue with the task returned by the given closure.

     - parameter executor: Determines how the the closure is called. The default is to call the closure immediately.
     - parameter closure:  The closure that returns the continuation task.
     The returned task will complete when the continuation task completes.

     - returns: A task that will continue with the task returned by the given closure.
     */
    public class func execute(_ executor: Executor = .default, closure: @escaping (() throws -> TResult)) -> Task {
        return Task(executor, closure: closure)
    }

    /**
     Creates a task that will continue with the task returned by the given closure.

     - parameter executor: Determines how the the closure is called. The default is to call the closure immediately.
     - parameter closure:  The closure that returns the continuation task.
     The returned task will complete when the continuation task completes.

     - returns: A task that will continue with the task returned by the given closure.
     */
    public class func executeWithTask(_ executor: Executor = .default, closure: @escaping (() throws -> Task)) -> Task {
        return emptyTask().continueWithTask(executor) { _ in
            return try closure()
        }
    }

    // MARK: State Accessors

    ///  Whether this task is completed. A completed task can also be faulted or cancelled.
    public var completed: Bool {
        switch state {
        case .pending:
            return false
        default:
            return true
        }
    }

    ///  Whether this task has completed due to an error or exception. A `faulted` task is also completed.
    public var faulted: Bool {
        switch state {
        case .error:
            return true
        default:
            return false
        }
    }

    /// Whether this task has been cancelled. A `cancelled` task is also completed.
    public var cancelled: Bool {
        switch state {
        case .cancelled:
            return true
        default:
            return false
        }
    }

    /// The result of a successful task. Won't be set until the task completes with a `result`.
    public var result: TResult? {
        switch state {
        case .success(let result):
            return result
        default:
            break
        }
        return nil
    }

    /// The error of a errored task. Won't be set until the task completes with `error`.
    public var error: Error? {
        switch state {
        case .error(let error):
            return error
        default:
            break
        }
        return nil
    }

    /**
     Waits until this operation is completed.

     This method is inefficient and consumes a thread resource while it's running.
     It should be avoided. This method logs a warning message if it is used on the main thread.
     */
    public func waitUntilCompleted() {
        if Thread.isMainThread {
            debugPrint("Warning: A long-running operation is being executed on the main thread waiting on \(self).")
        }

        var conditon: NSCondition?
        synchronizationQueue.sync(flags: .barrier, execute: {
            if case .pending = self._state {
                conditon = self._completedCondition ?? NSCondition()
                self._completedCondition = conditon
            }
        })

        guard let condition = conditon else {
            // Task should have been completed
            precondition(completed)
            return
        }

        condition.lock()
        while !completed {
            condition.wait()
        }
        condition.unlock()

        synchronizationQueue.sync(flags: .barrier, execute: {
            self._completedCondition = nil
        })
    }

    // MARK: State Change

    @discardableResult
    func trySet(state: TaskState<TResult>) -> Bool {
        var stateChanged = false

        var continuations: [Continuation]?
        var completedCondition: NSCondition?
        synchronizationQueue.sync(flags: .barrier, execute: {
            switch self._state {
            case .pending:
                stateChanged = true
                self._state = state
                continuations = self._continuations
                completedCondition = self._completedCondition
                self._continuations.removeAll()
            default:
                break
            }
        })
        if stateChanged {
            completedCondition?.lock()
            completedCondition?.broadcast()
            completedCondition?.unlock()

            for continuation in continuations! {
                continuation()
            }
        }

        return stateChanged
    }

    // MARK: Internal

    func appendOrRunContinuation(_ continuation: @escaping Continuation) {
        var runContinuation = false
        synchronizationQueue.sync(flags: .barrier, execute: {
            switch self._state {
            case .pending:
                self._continuations.append(continuation)
            default:
                runContinuation = true
            }
        })
        if runContinuation {
            continuation()
        }
    }

    var state: TaskState<TResult> {
        var value: TaskState<TResult>?
        synchronizationQueue.sync {
            value = self._state
        }
        return value!
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
