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

class TaskTests: XCTestCase {

    // MARK: Initializers

    func testWithResult() {
        let task = Task(name)

        XCTAssertNotNil(task.result)
        XCTAssertEqual(task.result, name)
        XCTAssertTrue(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)
        XCTAssertNil(task.error)
    }

    func testWithError() {
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)
        let task = Task<String>(error: error)

        XCTAssertNil(task.result)
        XCTAssertTrue(task.completed)
        XCTAssertTrue(task.faulted)
        XCTAssertFalse(task.cancelled)
        XCTAssertNotNil(task.error)
        XCTAssertEqual(task.error as NSError?, error)
    }

    func testCancelledTask() {
        let task = Task<String>.cancelledTask()

        XCTAssertNil(task.result)
        XCTAssertTrue(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertTrue(task.cancelled)
        XCTAssertNil(task.error)
    }

    // MARK: Task with Delay

    func testWithDelay() {
        let expectation = self.expectation(description: name)
        let task = Task<String>.withDelay(0.01)
        task.continueWith { task in
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        waitForTestExpectations()
    }

    // MARK: Execute

    func testExecuteWithClosureReturningNil() {
        let expectation = self.expectation(description: name)
        let task = Task<String> {
            expectation.fulfill()
            return "Hello, World!"
        }
        waitForTestExpectations()
        XCTAssertEqual(task.result, "Hello, World!")
    }

    func testConstructorWithClosureReturningValue() {
        let expectation = self.expectation(description: name)
        let task = Task<String> {
            expectation.fulfill()
            return self.name
        }
        waitForTestExpectations()
        XCTAssertNotNil(task.result)
        XCTAssertEqual(task.result, name)
    }

    func testExecuteWithClosureReturningValue() {
        let expectation = self.expectation(description: name)
        let task = Task<String>.execute {
            expectation.fulfill()
            return self.name
        }
        waitForTestExpectations()
        XCTAssertNotNil(task.result)
        XCTAssertEqual(task.result, name)
    }

    func testExecuteWithClosureReturningTaskWithResult() {
        let expectation = self.expectation(description: name)
        let task = Task.executeWithTask { () -> Task<Int> in
            expectation.fulfill()
            return Task(10)
        }
        waitForTestExpectations()
        XCTAssertNotNil(task.result)
        XCTAssertEqual(task.result, 10)
    }

    func testExecuteWithClosureReturningCancelledTask() {
        let expectation = self.expectation(description: name)
        let task = Task<Void>.executeWithTask { () -> Task<Void> in
            expectation.fulfill()
            return Task.cancelledTask()
        }
        waitForTestExpectations()
        XCTAssertTrue(task.cancelled)
    }

    func textExecuteWithClosureThrowingError() {
        let expectation = self.expectation(description: name)
        let task = Task<String>.execute {
            defer {
                expectation.fulfill()
            }
            throw NSError(domain: "com.bolts", code: 1, userInfo: nil)
        }
        waitForTestExpectations()
        XCTAssertNotNil(task.error)
    }

    func testExecuteWithClosureThrowingCancelledError() {
        let expectation = self.expectation(description: name)
        let task = Task<String>.execute {
            defer {
                expectation.fulfill()
            }
            throw CancelledError()
        }
        waitForTestExpectations()
        XCTAssertTrue(task.cancelled)
        XCTAssertNil(task.error)
    }

    func textExecuteWithTaskClosureThrowingError() {
        let expectation = self.expectation(description: name)
        let task = Task<String>.executeWithTask {
            defer {
                expectation.fulfill()
            }
            throw NSError(domain: "com.bolts", code: 1, userInfo: nil)
        }
        waitForTestExpectations()
        XCTAssertNotNil(task.error)
    }

    func testExecuteWithTaskClosureThrowingCancelledError() {
        let expectation = self.expectation(description: name)
        let task = Task<String>.executeWithTask {
            defer {
                expectation.fulfill()
            }
            throw CancelledError()
        }
        waitForTestExpectations()
        XCTAssertTrue(task.cancelled)
        XCTAssertNil(task.error)
    }

    // MARK: Continuations

    func testContinueWithOnSucessfulTaskByReturningResult() {
        let expectation = self.expectation(description: name)
        let initialTask = Task(1)

        let continuationTask = initialTask.continueWith { task -> String? in
            XCTAssertTrue(task === initialTask)
            return self.name
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForTestExpectations()
    }

    func testContinueWithOnErroredTaskByReturningResult() {
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)
        let expectation = self.expectation(description: name)
        let initialTask = Task<Int>(error: error)

        let continuationTask = initialTask.continueWith { task -> String? in
            XCTAssertTrue(task === initialTask)
            return self.name
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForTestExpectations()
    }

    func testContinueWithOnCancelledTaskByReturningResult() {
        let expectation = self.expectation(description: name)
        let initialTask = Task<Int>.cancelledTask()

        let continuationTask = initialTask.continueWith { task -> String? in
            XCTAssertTrue(task === initialTask)
            return self.name
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForTestExpectations()
    }

    func testContinueWithWithExecutor() {
        let expectation = self.expectation(description: name)
        let initialTask = Task<Int>.cancelledTask()
        let executorExpectation = self.expectation(description: "executor")

        let executor = Executor.closure {
            $0()
            executorExpectation.fulfill()
        }

        let continuationTask = initialTask.continueWith(executor) { task -> String? in
            XCTAssertTrue(task === initialTask)
            return self.name
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForTestExpectations()
    }

    func testContinueWithByReturningNilResult() {
        let expectation = self.expectation(description: name)
        let initialTask = Task(1)

        let continuationTask = initialTask.continueWith { task -> String? in
            XCTAssertTrue(task === initialTask)
            return nil
        }

        continuationTask.continueOnSuccessWith {
            XCTAssertNil($0)
            expectation.fulfill()
        }
        waitForTestExpectations()
    }

    func testContinueWithByReturningTask() {
        let expectation = self.expectation(description: name)
        let firstTask = Task(1)
        let secondTask = Task(name)

        let continuationTask = firstTask.continueWithTask { task -> Task<String> in
            XCTAssertTrue(task === firstTask)
            return secondTask
        }

        XCTAssertTrue(continuationTask !== secondTask)
        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForTestExpectations()
    }

    func testContinueWithByReturningNilTask() {
        let expectation = self.expectation(description: name)
        let initialTask = Task(1)

        let continuationTask = initialTask.continueWith { task in
            XCTAssertTrue(task === initialTask)
        }

        continuationTask.continueWith { task in
            expectation.fulfill()
        }
        waitForTestExpectations()
    }

    func testChainedContinueWithFunctions() {
        let expectation = self.expectation(description: name)
        var count = 0

        Task<Void>.cancelledTask().continueWith { _ -> String? in
            count += 1
            XCTAssertEqual(count, 1)
            return nil
        }.continueWith { _ -> String? in
            count += 1
            XCTAssertEqual(count, 2)
            return nil
        }.continueWith { _ -> String? in
            count += 1
            XCTAssertEqual(count, 3)
            return nil
        }.continueWith { _ -> String? in
            count += 1
            XCTAssertEqual(count, 4)
            return nil
        }.continueWith { _ -> String? in
            count += 1
            XCTAssertEqual(count, 5)
            expectation.fulfill()
            return nil
        }

        waitForTestExpectations()
    }

    func testChainedContinueWithWithAsyncExecutor() {
        let expectation = self.expectation(description: name)
        let executor = Executor.queue(DispatchQueue.global(qos: .default))
        var count = 0

        Task<Void>.cancelledTask().continueWith(executor) { _ in
            count += 1
            XCTAssertEqual(count, 1)
        }.continueWith(executor) { _ in
            count += 1
            XCTAssertEqual(count, 2)
        }.continueWith(executor) { _ in
            count += 1
            XCTAssertEqual(count, 3)
        }.continueWith(executor) { _ in
            count += 1
            XCTAssertEqual(count, 4)
        }.continueWith(executor) { _ in
            count += 1
            XCTAssertEqual(count, 5)
            expectation.fulfill()
        }

        waitForTestExpectations()
    }

    //--------------------------------------
    // MARK: - continueOnError
    //--------------------------------------

    func testContinueOnGenericErrorRecovers() {
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)
        let expectation = self.expectation(description: name)
        let initialTask = Task<String?>(error: error)

        let continuationTask = initialTask.continueOnErrorWith { taskError -> String? in
            XCTAssertEqual(taskError as NSError, error)
            return self.name
        }
        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForTestExpectations()
    }

    func testContinueOnSpecificErrorRecovers() {
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)
        let expectation = self.expectation(description: name)
        let initialTask = Task<String?>(error: error)

        let continuationTask = initialTask.continueOnErrorWith { (taskError: NSError) -> String? in
            XCTAssertEqual(taskError, error)
            return self.name
        }
        continuationTask.continueOnSuccessWith {
            XCTAssertEqual($0, self.name)
            expectation.fulfill()
        }
        waitForTestExpectations()
    }

    //--------------------------------------
    // MARK: - WhenAll
    //--------------------------------------

    func testWhenAllTasksEmptyArray() {
        let tasks: [Task<Int>] = []

        let expectation = self.expectation(description: name)
        Task.whenAll(tasks).continueWith { task in
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testWhenAllTasksSuccess() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0

        for i in 1...20 {
            let task = Task<Void>.withDelay(0.5)
                .continueWith(continuation: { task -> Int in
                    OSAtomicIncrement32(&count)
                    return i
                })
            tasks.append(task)
        }

        let expectation = self.expectation(description: name)
        let task = Task.whenAll(tasks).continueWith { task in
            XCTAssertEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testWhenAllTasksWithResultSuccess() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0
        let executor = Executor.queue(DispatchQueue.global(qos: .default))

        for i in 1...20 {
            let task = Task<Void>.withDelay(0.5)
                .continueWith(executor, continuation: { task -> Int in
                    OSAtomicIncrement32(&count)
                    return i
                })
            tasks.append(task)
        }

        let expectation = self.expectation(description: name)
        let task = Task.whenAllResult(tasks).continueWith { task in
            XCTAssertEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            XCTAssertEqual(Int32(task.result!.count), count)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForTestExpectations()
    }

    func testWhenAllTasksWithCancel() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0
        let executor = Executor.queue(DispatchQueue.global(qos: .default))

        for i in 1...20 {
            let task = Task<Void>.withDelay(0.5)
                .continueWithTask(executor, continuation: { task -> Task<Int> in
                    OSAtomicIncrement32(&count)
                    if i == 20 {
                        return Task.cancelledTask()
                    }
                    return Task(i)
                })
            tasks.append(task)
        }

        let expectation = self.expectation(description: name)
        let task = Task.whenAllResult(tasks).continueWith { task in
            XCTAssertEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertTrue(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForTestExpectations()
    }

    func testWhenAllTasksError() {
        var tasks: [Task<Void>] = []
        var count: Int32 = 0

        for i in 1...20 {
            let task = Task<Void>.withDelay(0.5)
                .continueWith(continuation: { task in
                    OSAtomicIncrement32(&count)
                    throw NSError(domain: "bolts", code: i, userInfo: nil)
                })
            tasks.append(task)
        }

        let expectation = self.expectation(description: name)
        let task = Task.whenAll(tasks).continueWith { task in
            XCTAssertEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertTrue(task.faulted)
            XCTAssertFalse(task.cancelled)
            guard let error = task.error as? AggregateError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            XCTAssertEqual(error.errors.count, Int(count))
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    // MARK: When Any

    func testWhenAnyTasksSuccess() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0
        let executor = Executor.queue(DispatchQueue.global(qos: .default))

        tasks.append(Task<Void>.withDelay(0.2).continueWith { task in
            // Use max value of Int32, so we can use the same code across both 32 and 64 bit archs.
            return Int(arc4random_uniform(UInt32(Int32.max)))
        })
        for i in 1...20 {
            let task = Task<Void>.withDelay(0.5)
                .continueWith(executor, continuation: { task -> Int in
                    OSAtomicIncrement32(&count)
                    return i
                })
            tasks.append(task)
        }

        let expectation = self.expectation(description: name)
        let task = Task.whenAny(tasks).continueWith { task in
            XCTAssertNotEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForTestExpectations()
    }

    func testWhenAnyTasksWithErrors() {
        var tasks = Array<Task<Void>>()
        var count: Int32 = 0

        let executor = Executor.queue(DispatchQueue.global(qos: .default))
        let error = NSError(domain: "com.bolts", code: 1, userInfo: nil)

        for i in 1...20 {
            let task = Task<Void>.withDelay(Double(i) * 0.5)
                .continueWithTask(executor, continuation: { task -> Task<Void> in
                    OSAtomicIncrement32(&count)
                    return Task(error: error)
                })
            tasks.append(task)
        }

        let expectation = self.expectation(description: name)
        let task = Task.whenAny(tasks).continueWith { task in
            XCTAssertNotEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForTestExpectations()
    }

    func testWhenAnyTasksWithCancel() {
        var tasks = Array<Task<Int>>()
        var count: Int32 = 0

        let executor = Executor.queue(DispatchQueue.global(qos: .default))

        for i in 1...20 {
            let task = Task<Void>.withDelay(Double(i) * 0.5)
                .continueWithTask(executor, continuation: { task -> Task<Int> in
                    OSAtomicIncrement32(&count)
                    return Task.cancelledTask()
                })
            tasks.append(task)
        }

        let expectation = self.expectation(description: name)
        let task = Task.whenAny(tasks).continueWith { task in
            XCTAssertNotEqual(count, Int32(tasks.count))
            XCTAssertTrue(task.completed)
            XCTAssertFalse(task.faulted)
            XCTAssertFalse(task.cancelled)
            expectation.fulfill()
        }

        XCTAssertFalse(task.completed)
        XCTAssertFalse(task.faulted)
        XCTAssertFalse(task.cancelled)

        waitForTestExpectations()
    }

    // MARK: Wait

    func testTaskWait() {
        Task<Void>.withDelay(0.5).waitUntilCompleted()
    }

    func testCompletedTaskWait() {
        Task(self.name).waitUntilCompleted()
    }

    func testTaskChainWait() {
        var count = 0

        Task<Void>.cancelledTask().continueWith { _ in
            count += 1
            XCTAssertEqual(count, 1)
        }.continueWith { _ in
            count += 1
            XCTAssertEqual(count, 2)
        }.continueWith { _ in
            count += 1
            XCTAssertEqual(count, 3)
        }.continueWith { _ in
            count += 1
            XCTAssertEqual(count, 4)
        }.continueWith { _ in
            count += 1
            XCTAssertEqual(count, 5)
        }.waitUntilCompleted()
        XCTAssertEqual(count, 5)
    }
}
