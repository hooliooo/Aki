//
//  Aki
//  Created by Julio Miguel Alorro on 02.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import class Foundation.Operation

/**
 AsyncOperation is an abstract subclass of AkiOperation that is meant to be subclassed by asynchronous Operations.

 This implementation provides the necessary boilerplate code for creating asyncrhonous Operations.
*/
open class AsyncOperation<T>: AkiOperation<T> {

    /**
     Initializer.
    */
    public override init() {
        guard type(of: self) != AsyncOperation.self else {
            fatalError(
                "AsyncOperation instances cannot be created. Use subclasses instead"
            )
        }
        super.init()
    }

    // Override properties
    override public final var isAsynchronous: Bool {
        return true
    }
}
