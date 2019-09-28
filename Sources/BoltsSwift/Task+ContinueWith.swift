/*
 *  Copyright (c) 2016, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation

//--------------------------------------
// MARK: - ContinueWith
//--------------------------------------

extension Task {
    /**
     Internal continueWithTask. This is the method that all other continuations must go through.

     - parameter executor:     The executor to invoke the closure on.
     - parameter options:      The options to run the closure with
     - parameter continuation: The closure to execute.

     - returns: The task resulting from the continuation
     */
    fileprivate func continueWithTask<S>(_ executor: Executor,
                                         options: TaskContinuationOptions,
                                         continuation: @escaping ((Task) throws -> Task<S>)
    ) -> Task<S> {
        let taskCompletionSource = TaskCompletionSource<S>()
        let wrapperContinuation = {
            switch self.state {
            case .success where options.contains(.RunOnSuccess): fallthrough
            case .error where options.contains(.RunOnError): fallthrough
            case .cancelled where options.contains(.RunOnCancelled):
                executor.execute {
                    let wrappedState = TaskState<Task<S>>.fromClosure {
                        try continuation(self)
                    }
                    switch wrappedState {
                    case .success(let nextTask):
                        switch nextTask.state {
                        case .pending:
                            nextTask.continueWith { nextTask in
                                taskCompletionSource.setState(nextTask.state)
                            }
                        default:
                            taskCompletionSource.setState(nextTask.state)
                        }
                    case .error(let error):
                        taskCompletionSource.set(error: error)
                    case .cancelled:
                        taskCompletionSource.cancel()
                    default: abort() // This should never happen.
                    }
                }

            case .success(let result as S):
                // This is for continueOnErrorWith - the type of the result doesn't change, so we can pass it through
                taskCompletionSource.set(result: result)

            case .error(let error):
                taskCompletionSource.set(error: error)

            case .cancelled:
                taskCompletionSource.cancel()

            default:
                fatalError("Task was in an invalid state \(self.state)")
            }
        }
        appendOrRunContinuation(wrapperContinuation)
        return taskCompletionSource.task
    }

    /**
     Enqueues a given closure to be run once this task is complete.

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns the result of the task.

     - returns: A task that will be completed with a result from a given closure.
     */
    @discardableResult
    public func continueWith<S>(_ executor: Executor = .default, continuation: @escaping ((Task) throws -> S)) -> Task<S> {
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
    @discardableResult
    public func continueWithTask<S>(_ executor: Executor = .default, continuation: @escaping ((Task) throws -> Task<S>)) -> Task<S> {
        return continueWithTask(executor, options: .RunAlways, continuation: continuation)
    }
}

//--------------------------------------
// MARK: - ContinueOnSuccessWith
//--------------------------------------

extension Task {
    /**
     Enqueues a given closure to be run once this task completes with success (has intended result).

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    @discardableResult
    public func continueOnSuccessWith<S>(_ executor: Executor = .default,
                                         continuation: @escaping ((TResult) throws -> S)) -> Task<S> {
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
    @discardableResult
    public func continueOnSuccessWithTask<S>(_ executor: Executor = .default,
                                             continuation: @escaping ((TResult) throws -> Task<S>)) -> Task<S> {
        return continueWithTask(executor, options: .RunOnSuccess) { task in
            return try continuation(task.result!)
        }
    }
}

//--------------------------------------
// MARK: - ContinueOnErrorWith
//--------------------------------------

extension Task {
    /**
     Enqueues a given closure to be run once this task completes with error.

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    @discardableResult
    public func continueOnErrorWith<E: Error>(_ executor: Executor = .default, continuation: @escaping ((E) throws -> TResult)) -> Task {
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
    @discardableResult
    public func continueOnErrorWith(_ executor: Executor = .default, continuation: @escaping ((Error) throws -> TResult)) -> Task {
        return continueOnErrorWithTask(executor) { (error: Error) in
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
    @discardableResult
    public func continueOnErrorWithTask<E: Error>(_ executor: Executor = .default, continuation: @escaping ((E) throws -> Task)) -> Task {
        return continueOnErrorWithTask(executor) { (error: Error) in
            if let error = error as? E {
                return try continuation(error)
            }
            return Task(state: .error(error))
        }
    }

    /**
     Enqueues a given closure to be run once this task completes with error.

     - parameter executor:     Determines how the the closure is called. The default is to call the closure immediately.
     - parameter continuation: The closure that returns a task to chain on.

     - returns: A task that will be completed when a task returned from a closure is completed.
     */
    @discardableResult
    public func continueOnErrorWithTask(_ executor: Executor = .default, continuation: @escaping ((Error) throws -> Task)) -> Task {
        return continueWithTask(executor, options: .RunOnError) { task in
            return try continuation(task.error!)
        }
    }
}
