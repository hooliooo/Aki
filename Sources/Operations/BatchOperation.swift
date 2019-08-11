//
//  Aki
//  Created by Julio Miguel Alorro on 04.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import Foundation

open class BatchOperation: AkiOperation<Void> {

    // MARK: Initializers
    public init(operations: [Operation], queueConfiguration: (OperationQueue) -> Void) {
        super.init()
        queueConfiguration(self.internalQueue)

        self.finishingOperation = BlockOperation { [weak self] () -> Void in
            print("Finished Batch Operation")
            self?.set(value: ())
            self?.state = .finished
        }
        self.internalQueue.isSuspended = true
        self.finishingOperation.addDependency(self.startingOperation)

        for operation in operations {
            operation.addDependency(self.startingOperation)
            self.finishingOperation.addDependency(operation)
        }

        self.internalQueue.addOperation(self.startingOperation)
        for operation in operations {
            self.internalQueue.addOperation(operation)
        }

    }

    // MARK: Stored Properties
    private let startingOperation: BlockOperation = BlockOperation(block: {})
    private var finishingOperation: BlockOperation!
    public let internalQueue: OperationQueue = OperationQueue()

    public override final var isAsynchronous: Bool {
        return true
    }

    open override func start() {
        self.internalQueue.isSuspended = false
        self.internalQueue.addOperation(self.finishingOperation)
        super.start()
    }

    open override func cancel() {
        self.internalQueue.cancelAllOperations()
        super.cancel()
    }

}
