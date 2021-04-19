import Foundation

public final class FakeOperationQueue: OperationQueue {
    public var runSynchronously: Bool = false

    public func reset() {
        internalOperations = []
    }

    public func runNextOperation() {
        guard internalOperations.count > 0 else { return }
        if let op = internalOperations.first {
            performOperationAndWait(op)
            internalOperations.remove(at: 0)
        }
    }

    public override func addOperation(_ op: Operation) {
        if runSynchronously {
            performOperationAndWait(op)
        } else {
            internalOperations.append(op)
        }
    }

    public override func addOperations(_ operations: [Operation], waitUntilFinished wait: Bool) {
        for op in operations {
            addOperation(op)
        }
        if wait {
            while self.operationCount > 0 {
                self.runNextOperation()
            }
        }
    }

    public override func addOperation(_ block: @escaping () -> Void) {
        if runSynchronously {
            block()
        } else {
            addOperation(BlockOperation(block: block))
        }
    }

    public override func cancelAllOperations() {
        for op in internalOperations {
            op.cancel()
        }
        reset()
    }

    public override init() {
        super.init()
        isSuspended = true
        reset()
    }

    public override var operationCount: Int {
        return internalOperations.count
    }

    private var internalOperations: [Operation] = []

    private func performOperationAndWait(_ op: Operation) {
        op.start()
        op.waitUntilFinished()
    }
}
