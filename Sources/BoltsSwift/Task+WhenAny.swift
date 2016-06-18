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
                taskCompletionSource.trySet(result: ())
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
