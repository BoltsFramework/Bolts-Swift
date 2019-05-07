//
//  CancellationTests.swift
//  BoltsSwift
//
//  Created by Simon Brockmann on 07.05.19.
//  Copyright © 2019 Facebook. All rights reserved.
//

import XCTest
import BoltsSwift

class CancellationTests: XCTestCase {
    func testCancel() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        XCTAssertFalse(cts.isCancellationRequested(), "Source should not be cancelled")
        XCTAssertFalse(cts.token.cancellationRequested, "Token should not be cancelled")

        try cts.cancel()

        XCTAssertTrue(cts.isCancellationRequested(), "Source should be cancelled")
        XCTAssertTrue(cts.token.cancellationRequested, "Token should be cancelled")
    }

    func testCancelMultipleTimes() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        XCTAssertFalse(cts.isCancellationRequested())
        XCTAssertFalse(cts.token.cancellationRequested)

        try cts.cancel()
        XCTAssertTrue(cts.isCancellationRequested());
        XCTAssertTrue(cts.token.cancellationRequested);

        try cts.cancel()
        XCTAssertTrue(cts.isCancellationRequested());
        XCTAssertTrue(cts.token.cancellationRequested);
    }

    func testCancellationBlock() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        var cancelled = false
        cts.token.registerCancellationObserver {
            cancelled = true
        }
        XCTAssertFalse(cts.isCancellationRequested(), "Source should not be cancelled");
        XCTAssertFalse(cts.token.cancellationRequested, "Token should not be cancelled");

        try cts.cancel()

        XCTAssertTrue(cancelled, "Source should be cancelled");
    }

    func testCancellationAfterDelay() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        XCTAssertFalse(cts.isCancellationRequested(), "Source should not be cancelled");
        XCTAssertFalse(cts.token.cancellationRequested, "Token should not be cancelled");

        try cts.cancelAfterInterval(interval: 0.2)
        XCTAssertFalse(cts.isCancellationRequested(), "Source should be cancelled")
        XCTAssertFalse(cts.token.cancellationRequested, "Token should be cancelled")

        // Spin the run loop for half a second, since `delay` is in milliseconds, not seconds.
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))

        XCTAssertTrue(cts.isCancellationRequested(), "Source should be cancelled")
        XCTAssertTrue(cts.token.cancellationRequested, "Token should be cancelled")
    }

    func testCancellationAfterDelayValidation() {
        let cts = CancellationTokenSource.cancellationTokenSource()
        XCTAssertFalse(cts.isCancellationRequested())
        XCTAssertFalse(cts.token.cancellationRequested)

        XCTAssertThrowsError(try cts.cancelAfterInterval(interval: -1))
    }

    func testCancellationAfterZeroDelay() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        XCTAssertFalse(cts.isCancellationRequested())
        XCTAssertFalse(cts.token.cancellationRequested)

        try cts.cancelAfterInterval(interval: 0)

        XCTAssertTrue(cts.isCancellationRequested());
        XCTAssertTrue(cts.token.cancellationRequested);
    }

    func testCancellationAfterDelayOnCancelled() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        try cts.cancel()
        XCTAssertTrue(cts.isCancellationRequested())
        XCTAssertTrue(cts.token.cancellationRequested)

        try cts.cancelAfterInterval(interval: 1)

        XCTAssertTrue(cts.isCancellationRequested())
        XCTAssertTrue(cts.token.cancellationRequested)
    }

    func testDispose() throws {
        var cts = CancellationTokenSource.cancellationTokenSource()
        try cts.dispose()

        XCTAssertThrowsError(try cts.cancel())

        cts = CancellationTokenSource.cancellationTokenSource()
        try cts.cancel()

        XCTAssertTrue(cts.isCancellationRequested(), "Source should be cancelled")
        XCTAssertTrue(cts.token.cancellationRequested, "Token should be cancelled")

        try cts.dispose()
        XCTAssertThrowsError(try cts.cancel())
    }

    func testDisposeMultipleTimes() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        try cts.dispose()
        XCTAssertNoThrow(try cts.dispose())
    }

    func testDisposeRegistration() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        let regestration = cts.token.registerCancellationObserver {
            XCTFail()
        }!
        XCTAssertNoThrow(try regestration.dispose())
        try cts.cancel()
    }

    func testDisposeRegistrationMultipleTimes() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        let regestration = cts.token.registerCancellationObserver {
            XCTFail()
        }!
        XCTAssertNoThrow(try regestration.dispose())
        XCTAssertNoThrow(try regestration.dispose())

        try cts.cancel()
    }

    func testDisposeRegistrationAfterCancellationToken() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        let regestration = cts.token.registerCancellationObserver {
        }

        try regestration!.dispose()
        try cts.cancel()
    }

    func testDisposeRegistrationBeforeCancellationToken() throws {
        let cts = CancellationTokenSource.cancellationTokenSource()
        let registration = cts.token.registerCancellationObserver {
        }!

        try cts.dispose()
        XCTAssertNoThrow(try registration.dispose())
    }
}
