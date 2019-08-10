//
//  Aki
//  Created by Julio Miguel Alorro on 10.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import class Foundation.Operation

public extension Operation {

    var aki: AkiOperationDSL {
        return AkiOperationDSL(base: self)
    }

}

public struct AkiOperationDSL {

    // MARK: Stored Properties
    public let base: Operation

    // MARK: Methods
    public func add(completionBlock: @escaping () -> Void) {

        if let currentCompletionBlock = self.base.completionBlock {
            self.base.completionBlock = {
                currentCompletionBlock()
                completionBlock()
            }
        } else {
            self.base.completionBlock = completionBlock
        }
    }

    public func add(dependencies: [Operation]) {
        for dependency in dependencies { self.base.addDependency(dependency) }
    }

}
