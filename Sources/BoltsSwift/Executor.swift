/*
 *  Copyright (c) 2016, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation

/// `Executor` is an `enum`, that defines different strategies for calling closures.
public enum Executor {

    /**
     Calls closures immediately unless the call stack gets too deep,
     in which case it dispatches the closure in the default priority queue.
     */
    case `default`

    /**
     Calls closures immediately.
     Tasks continuations will be run in the thread of the previous task.
     */
    case immediate

    /**
     Calls closures on the main thread.
     Will execute synchronously if already on the main thread, otherwise - will execute asynchronously.
     */
    case mainThread

    /**
     Dispatches closures on a GCD queue.
     */
    case queue(DispatchQueue)

    /**
     Adds closures to an operation queue.
     */
    case operationQueue(Foundation.OperationQueue)

    /**
     Passes closures to an executing closure.
     */
    case closure((() -> Void) -> Void)
    
    /**
     Passes escaping closures to an executing closure.
     */
    case escapingClosure((@escaping () -> Void) -> Void)

    /**
     Executes the given closure using the corresponding strategy.

     - parameter closure: The closure to execute.
     */
    public func execute(_ closure: @escaping () -> Void) {
        switch self {
        case .default:
            struct Static {
                static let taskDepthKey = "com.bolts.TaskDepthKey"
                static let maxTaskDepth = 20
            }

            let localThreadDictionary = Thread.current.threadDictionary

            var previousDepth: Int
            if let depth = localThreadDictionary[Static.taskDepthKey] as? Int {
                previousDepth = depth
            } else {
                previousDepth = 0
            }

            if previousDepth > Static.maxTaskDepth {
                DispatchQueue.global(qos: .default).async(execute: closure)
            } else {
                localThreadDictionary[Static.taskDepthKey] = previousDepth + 1
                closure()
                localThreadDictionary[Static.taskDepthKey] = previousDepth
            }
        case .immediate:
            closure()
        case .mainThread:
            if Thread.isMainThread {
                closure()
            } else {
                DispatchQueue.main.async(execute: closure)
            }
        case .queue(let queue):
            queue.async(execute: closure)
        case .operationQueue(let operationQueue):
            operationQueue.addOperation(closure)
        case .closure(let executingClosure):
            executingClosure(closure)
        case .escapingClosure(let executingEscapingClosure):
            executingEscapingClosure(closure)
        }
    }
}

extension Executor : CustomStringConvertible, CustomDebugStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        switch self {
        case .default:
            return "Default Executor"
        case .immediate:
            return "Immediate Executor"
        case .mainThread:
            return "MainThread Executor"
        case .queue:
            return "Executor with dispatch_queue"
        case .operationQueue:
            return "Executor with NSOperationQueue"
        case .closure:
            return "Executor with custom closure"
        case .escapingClosure:
            return "Executor with custom escaping closure"
        }
    }

    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        switch self {
        case .queue(let object):
            return "\(description): \(object)"
        case .operationQueue(let queue):
            return "\(description): \(queue)"
        case .closure(let closure):
            return "\(description): \(closure)"
        case .escapingClosure(let closure):
            return "\(description): \(closure)"
        default:
            return description
        }
    }
}
