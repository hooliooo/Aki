//
//  Aki
//  Created by Julio Miguel Alorro on 04.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import class Foundation.Operation
import class Foundation.OperationQueue

open class AkiOperationManager {

    public init(queueConfiguration: (OperationQueue) -> Void) {
        self.queue = OperationQueue()
        queueConfiguration(self.queue)
    }

    // MARK: Stored Properties
    private let queue: OperationQueue

    // MARK: Computed Properties
    public var operations: [Operation] {
        return self.queue.operations
    }

    // MARK: Methods
    public final func enqueue(_ operation: Operation) {
        self.queue.addOperation(operation)
    }

    public final func enqueue(operations: [Operation]) {
        self.queue.addOperations(operations, waitUntilFinished: false)
    }

    public final func enqueue(operations: Operation...) {
        self.enqueue(operations: operations)
    }

}
