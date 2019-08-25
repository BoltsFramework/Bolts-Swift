//
//  CancellationToken.swift
//  BoltsSwift
//
//  Copyright © 2019 Facebook. All rights reserved.
//

import Foundation

public typealias CancellationObserver = () -> Void

public final class CancellationToken {
    public var cancellationRequested: Bool {
        get {
            return synchronizationQueue.sync(flags: .barrier) { () -> Bool in
                return _cancellationRequested

            }
        }
    }

    private let synchronizationQueue = DispatchQueue(label: "com.bolts.cancellationToken", attributes: DispatchQueue.Attributes.concurrent)
    private var _cancellationRequested: Bool
    private var _regestrations = [CancellationTokenRegistration]()
    private var _disposed: Bool
    private var _cancelDelayedWorkItem: DispatchWorkItem?

    public init() {
        _cancellationRequested = false
        _disposed = false
    }

    @discardableResult
    public func registerCancellationObserver(observer: @escaping CancellationObserver) -> CancellationTokenRegistration? {
        return synchronizationQueue.sync(flags: .barrier) { () -> CancellationTokenRegistration? in
            if _disposed {
                return nil
            }
            let registration = CancellationTokenRegistration.registrationWithToken(token: self, observer: observer)
            _regestrations.append(registration)
            return registration
        }
    }

    internal func unrigsterRegistration(registration: CancellationTokenRegistration) throws {
        try synchronizationQueue.sync(flags: .barrier) { () -> Void in
            try throwIfDisposed()
            if let index = _regestrations.firstIndex(where: { $0 === registration }) {
                _regestrations.remove(at: index)
            }
        }
    }

    internal func cancel() throws {
        var registrations: [CancellationTokenRegistration]?
        try synchronizationQueue.sync(flags: .barrier) { () -> Void in
            try throwIfDisposed()
            if _cancellationRequested {
                return
            }
            if let cancelWorkItem = _cancelDelayedWorkItem {
                cancelWorkItem.cancel()
                _cancelDelayedWorkItem = nil
            }
            _cancellationRequested = true
            registrations = [CancellationTokenRegistration](_regestrations)
        }
        if registrations == nil {
            return
        }
        try notifyCancellation(registrations: registrations!)
    }

    private func notifyCancellation(registrations: [CancellationTokenRegistration]) throws {
        for registration in registrations {
            try registration.notifyDelegate()
        }
    }

    internal func cancelAfterInterval(interval: TimeInterval) throws {
        try throwIfDisposed()

        if interval < 0 {
            throw IntervalError()
        }

        if interval == 0 {
            try cancel()
            return
        }

        try synchronizationQueue.sync(flags: .barrier) { () -> Void in
            try throwIfDisposed()
            if let cancelWorkItem = _cancelDelayedWorkItem {
                cancelWorkItem.cancel()
                _cancelDelayedWorkItem = nil
            }
            if _cancellationRequested {
                return
            }
            _cancelDelayedWorkItem = DispatchWorkItem { [weak self] in
                try? self?.cancel()
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: _cancelDelayedWorkItem!)
        }
    }

    internal func dispose() throws {
        var registrations: [CancellationTokenRegistration]?
        synchronizationQueue.sync(flags: .barrier) { () -> Void in
            if _disposed {
                return
            }
            registrations = [CancellationTokenRegistration](_regestrations)
            _regestrations.removeAll()
        }
        if registrations != nil {
            try registrations!.forEach {
                try $0.dispose()
            }
        }
        synchronizationQueue.sync(flags: .barrier, execute: { () -> Void in
            _disposed = true
        })
    }

    private func throwIfDisposed() throws {
        if _disposed {
            throw DisposedError()
        }
    }
}
