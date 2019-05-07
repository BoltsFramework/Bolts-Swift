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
    public class func withDelay(_ delay: TimeInterval) -> Task<Void> {
        let taskCompletionSource = TaskCompletionSource<Void>()
        let time = DispatchTime.now() + delay
        DispatchQueue.global(qos: .default).asyncAfter(deadline: time) {
            taskCompletionSource.trySet(result: ())
        }
        return taskCompletionSource.task
    }

    public class func withDelay(_ delay: TimeInterval, _ cancellationToken: CancellationToken) -> Task<Void> {
        let taskCompletionSource = TaskCompletionSource<Void>()

        if cancellationToken.cancellationRequested {
            taskCompletionSource.cancel()
            return taskCompletionSource.task
        }

        let dispatchItem = DispatchWorkItem {
            if cancellationToken.cancellationRequested {
                taskCompletionSource.cancel()
                return
            }
            taskCompletionSource.trySet(result: ())
        }

        let time = DispatchTime.now() + delay
        DispatchQueue.global(qos: .default).asyncAfter(deadline: time, execute: dispatchItem)

        cancellationToken.registerCancellationObserver {
            dispatchItem.cancel()
            taskCompletionSource.tryCancel()
        }
        return taskCompletionSource.task
    }
}
