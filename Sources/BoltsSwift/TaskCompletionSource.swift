/*
 *  Copyright (c) 2016, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation

/// A `TaskCompletionSource<TResult>` represents the producer side of a `Task<TResult>`,
/// providing access to the consumer side through the `task` property.
/// As a producer, it can complete the underlying task by either by setting its result, error or cancelling it.
///
/// For example, this is how you could use a task completion source
/// to provide a task that asynchronously reads data from disk:
///
///     func dataFromPath(path: String) -> Task<NSData> {
///       let tcs = TaskCompletionSource<NSData>()
///       DispatchQueue.global(qos: .default).async {
///         if let data = NSData(contentsOfFile: path) {
///           tcs.set(result: data)
///         } else {
///           tcs.set(error: NSError(domain: "com.example", code: 0, userInfo: nil))
///         }
///       }
///       return tcs.task
///     }
public class TaskCompletionSource<TResult> {

    /// The underlying task.
    public let task = Task<TResult>()

    /// Creates a task completion source with a pending task.
    public init() {}

    //--------------------------------------
    // MARK: - Change Task State
    //--------------------------------------

    /**
     Completes the task with the given result.

     Throws an exception if the task is already completed.

     - parameter result: The task result.
     */
    public func set(result: TResult) {
        guard task.trySet(state: .success(result)) else {
            preconditionFailure("Can not set the result on a completed task.")
        }
    }

    /**
     Completes the task with the given error.

     Throws an exception if the task is already completed.

     - parameter error: The task error.
     */
    public func set(error: Error) {
        guard task.trySet(state: .error(error)) else {
            preconditionFailure("Can not set error on a completed task.")
        }
    }

    /**
     Cancels the task.

     Throws an exception if the task is already completed.
     */
    public func cancel() {
        guard task.trySet(state: .cancelled) else {
            preconditionFailure("Can not cancel a completed task.")
        }
    }

    /**
     Tries to complete the task with the given result.

     - parameter result: The task result.
     - returns: `true` if the result was set, `false` otherwise.
     */
    @discardableResult
    public func trySet(result: TResult) -> Bool {
        return task.trySet(state: .success(result))
    }

    /**
     Tries to completes the task with the given error.

     - parameter error: The task error.
     - returns: `true` if the error was set, `false` otherwise.
     */
    @discardableResult
    public func trySet(error: Error) -> Bool {
        return task.trySet(state: .error(error))
    }

    /**
     Cancels the task.

     - returns: `true` if the task was completed, `false` otherwise.
     */
    @discardableResult
    public func tryCancel() -> Bool {
        return task.trySet(state: .cancelled)
    }

    //--------------------------------------
    // MARK: - Change Task State (internal)
    //--------------------------------------

    func setState(_ state: TaskState<TResult>) {
        guard task.trySet(state: state) else {
            preconditionFailure("Can not complete a completed task.")
        }
    }
}
