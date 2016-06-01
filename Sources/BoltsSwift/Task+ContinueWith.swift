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
    private func continueWithTask<S>(executor: Executor, options: TaskContinuationOptions, continuation: (Task throws -> Task<S>)) -> Task<S> {
        let taskCompletionSource = TaskCompletionSource<S>()
        let wrapperContinuation = {
            switch self.state {
            case .Success where options.contains(.RunOnSuccess): fallthrough
            case .Error where options.contains(.RunOnError): fallthrough
            case .Cancelled where options.contains(.RunOnCancelled):
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

            case .Success(let result as S):
                // This is for continueOnErrorWith - the type of the result doesn't change, so we can pass it through
                taskCompletionSource.setResult(result)

            case .Error(let error):
                taskCompletionSource.setError(error)

            case .Cancelled:
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
        return continueWithTask(executor, options: .RunOnError) { task in
            return try continuation(task.error!)
        }
    }
}
