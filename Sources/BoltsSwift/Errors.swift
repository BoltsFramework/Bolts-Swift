/*
 *  Copyright (c) 2016, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

import Foundation

/**
 An error type that contains one or more underlying errors.
 */
public struct AggregateError: Error {
    /// An array of errors that are aggregated into this one.
    public let errors: [Error]

    init(errors: [Error]) {
        self.errors = errors
    }
}

/**
 An error type that indicates that the task was cancelled.

 Return or throw this from a continuation closure to propagate to the `task.cancelled` property.
 */
public struct CancelledError: Error {
    /**
     Initializes a Cancelled Error.
     */
    public init() { }
}

public struct DisposedError: Error {
    public init() {}
}

public struct IntervalError: Error {
    public init() {}
}
