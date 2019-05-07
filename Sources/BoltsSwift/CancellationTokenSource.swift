//
//  CancellationTokenSource.swift
//  BoltsSwift
//
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation

public final class CancellationTokenSource {
    public private(set) var token: CancellationToken

    public init() {
        token = CancellationToken()
    }

    public class func cancellationTokenSource() -> CancellationTokenSource {
        return CancellationTokenSource()
    }

    public func isCancellationRequested() -> Bool {
        return token.cancellationRequested
    }

    public func cancel() throws {
        try token.cancel()
    }

    public func cancelAfterInterval(interval: TimeInterval) throws {
        try token.cancelAfterInterval(interval: interval)
    }

    public func dispose() throws {
        try token.dispose()
    }
}
