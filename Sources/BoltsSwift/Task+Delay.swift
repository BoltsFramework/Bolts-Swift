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
            taskCompletionSource.trySet(result: ())
        }
        return taskCompletionSource.task
    }
}
