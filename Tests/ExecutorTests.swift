/*
 *  Copyright (c) 2016, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

import XCTest
import BoltsSwift

class ExecutorTests: XCTestCase {

    func testDefaultExecute() {
        let expectation = self.expectation(description: name)

        var finished = false
        Executor.default.execute {
            expectation.fulfill()
            finished = true
        }

        XCTAssertTrue(finished)
        waitForTestExpectations()
    }

    func testImmediateExecute() {
        let expectation = self.expectation(description: name)

        var finished = false
        Executor.immediate.execute {
            expectation.fulfill()
            finished = true
        }

        XCTAssertTrue(finished)
        waitForTestExpectations()
    }

    func testMainThreadSyncExecute() {
        let expectation = self.expectation(description: name)

        var finished = false
        Executor.mainThread.execute {
            expectation.fulfill()
            finished = true
        }

        XCTAssertTrue(finished)
        waitForTestExpectations()
    }

    func testMainThreadAsyncExecute() {
        let expectation = self.expectation(description: name)

        var finished = false
        DispatchQueue.global(qos: .default).async {
            Executor.mainThread.execute {
                finished = true
                expectation.fulfill()
            }
        }
        waitForTestExpectations()
        XCTAssertTrue(finished)
    }

    func testQueueExecute() {
        let expectation = self.expectation(description: name)
        let semaphore = DispatchSemaphore(value: 0)
        var finished = false

        Executor.queue(.global(qos: .default)).execute {
            semaphore.wait()
            finished = true
            expectation.fulfill()
        }

        XCTAssertFalse(finished)
        semaphore.signal()
        waitForTestExpectations()
        XCTAssertTrue(finished)
    }

    func testClosureExecute() {
        let expectation = self.expectation(description: name)

        Executor.closure { closure in
            closure()
        }.execute { () -> Void in
            expectation.fulfill()
        }

        waitForTestExpectations()
    }

    func testEscapingClosureExecute() {
        let expectation = self.expectation(description: name)
        Executor.escapingClosure { closure in
            closure()
        }.execute { () -> Void in
            expectation.fulfill()
        }

        waitForTestExpectations()
    }

    func testOperationQueueExecute() {
        let expectation = self.expectation(description: name)
        let semaphore = DispatchSemaphore(value: 0)
        var finished = false

        let operationQueue = OperationQueue()
        Executor.operationQueue(operationQueue).execute {
            semaphore.wait()
            finished = true
            expectation.fulfill()
        }

        XCTAssertFalse(finished)
        semaphore.signal()
        waitForTestExpectations()
        XCTAssertTrue(finished)
    }

    // MARK: Descriptions

    func testDescriptions() {
        XCTAssertFalse(Executor.default.description.isEmpty)
        XCTAssertFalse(Executor.immediate.description.isEmpty)
        XCTAssertFalse(Executor.mainThread.description.isEmpty)
        XCTAssertFalse(Executor.queue(.global(qos: .default)).description.isEmpty)
        XCTAssertFalse(Executor.operationQueue(OperationQueue.current!).description.isEmpty)
        XCTAssertFalse(Executor.closure({ _ in }).description.isEmpty)
    }

    func testDebugDescriptions() {
        XCTAssertFalse(Executor.default.debugDescription.isEmpty)
        XCTAssertFalse(Executor.immediate.debugDescription.isEmpty)
        XCTAssertFalse(Executor.mainThread.debugDescription.isEmpty)
        XCTAssertFalse(Executor.queue(.global(qos: .default)).debugDescription.isEmpty)
        XCTAssertFalse(Executor.operationQueue(OperationQueue.current!).debugDescription.isEmpty)
        XCTAssertFalse(Executor.closure({ _ in }).debugDescription.isEmpty)
    }
}
