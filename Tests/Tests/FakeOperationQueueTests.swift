import XCTest
import SpecHelperKit

final class FakeOperationQueueTests: XCTestCase {
    func testAsynchronousBehavior() {
        let subject = FakeOperationQueue()

        XCTAssertEqual(subject.operationCount, 0)

        var blockOperationRunCount = 0

        subject.addOperation(BlockOperation { blockOperationRunCount += 1 })
        XCTAssertEqual(subject.operationCount, 1)
        XCTAssertEqual(blockOperationRunCount, 0)

        subject.runNextOperation() // it runs the operation only when you tell it to.
        XCTAssertEqual(subject.operationCount, 0, "expected to remove ran operation from operations to run")
        XCTAssertEqual(blockOperationRunCount, 1, "expected to only run the operation once")
    }

    func testAsynchronousBehaviorWithBlocks() {
        let subject = FakeOperationQueue()

        XCTAssertEqual(subject.operationCount, 0)

        var blockOperationRunCount = 0

        // It creates a block operation from the block, instead of using whatever you gave it.
        subject.addOperation { blockOperationRunCount += 1 }
        XCTAssertEqual(subject.operationCount, 1)
        XCTAssertEqual(blockOperationRunCount, 0)

        subject.runNextOperation() // it runs the operation only when you tell it to.
        XCTAssertEqual(subject.operationCount, 0, "expected to remove ran operation from operations to run")
        XCTAssertEqual(blockOperationRunCount, 1, "expected to only run the operation once")
    }

    func testAsynchronousMultipleOperations() {
        let subject = FakeOperationQueue()

        var operation1RunCount = 0
        var operation2RunCount = 0
        var operation3RunCount = 0
        var operation4RunCount = 0

        subject.addOperation { operation1RunCount += 1 }
        subject.addOperation { operation2RunCount += 1 }

        XCTAssertEqual(subject.operationCount, 2)
        XCTAssertEqual(operation1RunCount, 0)
        XCTAssertEqual(operation2RunCount, 0)

        subject.addOperations([
            BlockOperation { operation3RunCount += 1 },
            BlockOperation { operation4RunCount += 1 }
        ], waitUntilFinished: false)

        XCTAssertEqual(subject.operationCount, 4)
        XCTAssertEqual(operation3RunCount, 0)
        XCTAssertEqual(operation4RunCount, 0)

        subject.runNextOperation() // Runs the first operation, because it's a queue.

        XCTAssertEqual(subject.operationCount, 3)
        XCTAssertEqual(operation1RunCount, 1)
        XCTAssertEqual(operation2RunCount, 0)
        XCTAssertEqual(operation3RunCount, 0)
        XCTAssertEqual(operation4RunCount, 0)

        subject.runNextOperation()

        XCTAssertEqual(subject.operationCount, 2)
        XCTAssertEqual(operation1RunCount, 1)
        XCTAssertEqual(operation2RunCount, 1)
        XCTAssertEqual(operation3RunCount, 0)
        XCTAssertEqual(operation4RunCount, 0)

        subject.runNextOperation()

        XCTAssertEqual(subject.operationCount, 1)
        XCTAssertEqual(operation1RunCount, 1)
        XCTAssertEqual(operation2RunCount, 1)
        XCTAssertEqual(operation3RunCount, 1)
        XCTAssertEqual(operation4RunCount, 0)

        subject.reset()

        XCTAssertEqual(subject.operationCount, 0)
        XCTAssertEqual(operation1RunCount, 1)
        XCTAssertEqual(operation2RunCount, 1)
        XCTAssertEqual(operation3RunCount, 1)
        XCTAssertEqual(operation4RunCount, 0)
    }

    func testAsynchronousWaitUntilFinished() {
        let subject = FakeOperationQueue()

        var operation1RunCount = 0
        var operation2RunCount = 0
        var operation3RunCount = 0
        var operation4RunCount = 0

        subject.addOperation { operation1RunCount += 1 }
        subject.addOperation { operation2RunCount += 1 }

        XCTAssertEqual(subject.operationCount, 2)
        XCTAssertEqual(operation1RunCount, 0)
        XCTAssertEqual(operation2RunCount, 0)

        subject.addOperations([
            BlockOperation { operation3RunCount += 1 },
            BlockOperation { operation4RunCount += 1 }
        ], waitUntilFinished: true)

        // Runs through all operations, including the ones just added.

        XCTAssertEqual(subject.operationCount, 0)
        XCTAssertEqual(operation1RunCount, 1)
        XCTAssertEqual(operation2RunCount, 1)
        XCTAssertEqual(operation3RunCount, 1)
        XCTAssertEqual(operation4RunCount, 1)

        XCTAssertFalse(subject.runSynchronously)
    }

    func testSynchronousImmediatelyRunsOperations() {
        let subject = FakeOperationQueue()
        subject.runSynchronously = true
        XCTAssertTrue(subject.runSynchronously)

        XCTAssertEqual(subject.operationCount, 0)

        var blockOperationRunCount = 0

        subject.addOperation(BlockOperation { blockOperationRunCount += 1 })
        XCTAssertEqual(subject.operationCount, 0)
        XCTAssertEqual(blockOperationRunCount, 1)

        blockOperationRunCount = 0

        subject.addOperation { blockOperationRunCount += 1 }
        XCTAssertEqual(subject.operationCount, 0)
        XCTAssertEqual(blockOperationRunCount, 1)

        var operation3RunCount = 0
        var operation4RunCount = 0

        subject.addOperations([
            BlockOperation { operation3RunCount += 1 },
            BlockOperation { operation4RunCount += 1 }
        ], waitUntilFinished: false) // runSynchronously takes priority over waitUntilFinished being false.

        XCTAssertEqual(subject.operationCount, 0)
        XCTAssertEqual(operation3RunCount, 1)
        XCTAssertEqual(operation4RunCount, 1)

        XCTAssertTrue(subject.runSynchronously, "Expected runSynchronously property to not be reset")
    }

    static var allTests = [
        ("testAsynchronousBehavior", testAsynchronousBehavior),
        ("testAsynchronousBehaviorWithBlocks", testAsynchronousBehaviorWithBlocks),
        ("testAsynchronousMultipleOperations", testAsynchronousMultipleOperations),
        ("testAsynchronousWaitUntilFinished", testAsynchronousWaitUntilFinished),
        ("testSynchronousImmediatelyRunsOperations", testSynchronousImmediatelyRunsOperations)
    ]
}
