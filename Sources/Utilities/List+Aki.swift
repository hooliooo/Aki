//
//  Aki
//  Copyright (c) 2019 Julio Miguel Alorro
//
//  Licensed under the MIT license. See LICENSE file.
//
//

import RealmSwift

extension List: AkiCopyable {

    public func unmanaged() -> List<Element> {
        let copy: List<Element> = List<Element>()

        for element in self {
            if let detachable = element as? AkiCopyable {
                let elementCopy = detachable.unmanaged() as! Element
                copy.append(elementCopy)
            } else {
                copy.append(element)
            }
        }
        return copy
    }

}
