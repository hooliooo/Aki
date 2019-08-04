//
//  Aki
//  Created by Julio Miguel Alorro on 03.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import class Foundation.Operation

/**
 AkiOperation is an abstract subclass of Operation.

 This implementation provides the necessary boilerplate code for creating custom Operations.
*/
open class AkiOperation<T>: Operation {

    /**
     Represents states of the AsyncOperation that can be set.
     */
    public enum State: String {
        /**
         The AkiOperation is in a ready state.
         */
        case ready

        /**
         The AkiOperation is currently executing.
         */
        case executing

        /**
         The AkiOperation is in a finished state.
        */
        case finished

        fileprivate var stringValue: String {
            return "is\(self.rawValue.capitalized)"
        }
    }

    /**
     Initializer.
     */
    public override init() {
        guard type(of: self) != AkiOperation.self else {
            fatalError(
                "AkiOperation instances cannot be created. Use subclasses instead"
            )
        }
        super.init()
    }

    /**
     The end value of the AkiOperation's task.
    */
    public internal(set) var value: T?

    /**
     The state of the AsyncOperation. Setting this value will trigger the necessary KVO functionality.
    */
    public var state: AkiOperation.State = AkiOperation.State.ready {
        willSet {
            self.willChangeValue(forKey: newValue.stringValue)
            self.willChangeValue(forKey: self.state.stringValue)
        }
        didSet {
            self.didChangeValue(forKey: oldValue.stringValue)
            self.didChangeValue(forKey: self.state.stringValue)
        }
    }

    // Override properties
    open override var isReady: Bool {
        return super.isReady && self.state == AkiOperation.State.ready
    }

    open override var isExecuting: Bool {
        return self.state == AkiOperation.State.executing
    }

    open override var isFinished: Bool {
        return self.state == AkiOperation.State.finished
    }

    // Override start
    open override func start() {
        if self.isCancelled {
            self.state = AkiOperation.State.finished
            return
        }

        self.main()
        self.state = AkiOperation.State.executing
    }
}

