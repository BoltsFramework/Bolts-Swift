//
//  CancellationTokenRegistration.swift
//  BoltsSwift
//
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation

public final class CancellationTokenRegistration {
    private var _disposed: Bool
    private let _synchronizationQueue = DispatchQueue(label: "com.bolts.cancellationTokenRegistration", attributes: DispatchQueue.Attributes.concurrent)
    private var _observer: CancellationObserver?
    private weak var _token: CancellationToken?

    private init(token: CancellationToken, observer: @escaping CancellationObserver) {
        _disposed = false
        _observer = observer
        _token = token
    }

    public class func registrationWithToken(token: CancellationToken, observer: @escaping CancellationObserver) -> CancellationTokenRegistration {
        return CancellationTokenRegistration(token: token, observer: observer)
    }

    public func dispose() throws {
        _synchronizationQueue.sync(flags: .barrier) { () -> Void in
            if _disposed {
                return
            }
            _disposed = true
        }
        if let token = _token {
            try token.unrigsterRegistration(registration: self)
            _token = nil
        }
        _observer = nil
    }

    internal func notifyDelegate() throws {
        try _synchronizationQueue.sync(flags: .barrier) { () -> Void in
            try throwIfDisposed()
            _observer?()
        }
    }

    private func throwIfDisposed() throws {
        if _disposed {
            throw DisposedError()
        }
    }
}
