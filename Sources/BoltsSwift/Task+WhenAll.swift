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
// MARK: - WhenAll
//--------------------------------------

extension Task {

    /**
     Creates a task that will be completed after all of the input tasks have completed.

     - parameter tasks: Array tasks to wait on for completion.

     - returns: A new task that will complete after all `tasks` are completed.
     */
    public class func whenAll(_ tasks: [Task]) -> Task<Void> {
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
                        #if swift(>=4.1)
                            tcs.set(error: AggregateError(errors: tasks.compactMap({ $0.error })))
                        #else
                            tcs.set(error: AggregateError(errors: tasks.flatMap({ $0.error })))
                        #endif
                    } else {
                        tcs.set(result: ())
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
    public class func whenAll(_ tasks: Task...) -> Task<Void> {
        return whenAll(tasks)
    }

    /**
     Creates a task that will be completed after all of the input tasks have completed.

     - parameter tasks: Array of tasks to wait on for completion.

     - returns: A new task that will complete after all `tasks` are completed.
     The result of the task is going an array of results of all tasks in the same order as they were provided.
     */
    public class func whenAllResult(_ tasks: [Task]) -> Task<[TResult]> {
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
    public class func whenAllResult(_ tasks: Task...) -> Task<[TResult]> {
        return whenAllResult(tasks)
    }
}
