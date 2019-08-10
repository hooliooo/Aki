//
//  Aki
//  Created by Julio Miguel Alorro on 04.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import Dispatch
import class Foundation.Operation
import class Foundation.OperationQueue
import class UIKit.UIApplication

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
    open func enqueue(_ operation: Operation) {
        self.queue.addOperation(operation)
    }

    open func enqueue(operations: [Operation]) {
        for operation in operations { self.enqueue(operation) }
    }

    open func enqueue(operations: Operation...) {
        self.enqueue(operations: operations)
    }

}

open class AkiNetworkOperationManager: AkiOperationManager {

    open override func enqueue(_ operation: Operation) {

        operation.aki.add(
            completionBlock: { () -> Void in
                DispatchQueue.main.async {
                    NetworkIndicatorController.shared.networkOperationDidEnd()
                }
            }
        )
        super.enqueue(operation)
        DispatchQueue.main.async {
            NetworkIndicatorController.shared.networkOperationDidStart()
        }
    }

    open override func enqueue(operations: [Operation]) {
        super.enqueue(operations: operations)
    }

    open override func enqueue(operations: Operation...) {
        super.enqueue(operations: operations)
    }

}

fileprivate class NetworkIndicatorController {

    fileprivate static let shared: NetworkIndicatorController = NetworkIndicatorController()

    private var networkOperationCount: Int = 0
    private let monitor: NetworkIndicatorController.Monitor = NetworkIndicatorController.Monitor()

    // MARK: Methods
    fileprivate func networkOperationDidStart() {
        self.networkOperationCount += 1
        self.updateNetworkIndicatorStatus()
    }

    fileprivate func networkOperationDidEnd() {
        self.networkOperationCount -= 1
        self.updateNetworkIndicatorStatus()
    }

    private func updateNetworkIndicatorStatus() {
        if self.networkOperationCount > 0 {
            self.showIndicator()
        } else {
            self.monitor.execute(after: 1) { [weak self] () -> Void in
                self?.hideIndicator()
            }
        }
    }

    private func showIndicator() {
        self.monitor.cancel()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    private func hideIndicator() {
        self.monitor.cancel()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

}

fileprivate extension NetworkIndicatorController {

    class Monitor {

        // MARK: Properties
        private var isCancelled = false

        func execute(after seconds: Int, block: @escaping () -> Void) {
            self.isCancelled = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(seconds)) {
                if !self.isCancelled {
                    block()
                }
            }
        }

        func cancel() {
            self.isCancelled = true
        }
    }

}

