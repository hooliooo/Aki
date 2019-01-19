//
//  Aki
//  Copyright (c) 2019 Julio Miguel Alorro
//
//  Licensed under the MIT license. See LICENSE file.
//
//

import RealmSwift

extension Object: AkiCopyable {

    public func unmanaged() -> Self {
        let copy = type(of: self).init()

        for property in self.objectSchema.properties {
            guard let value = self.value(forKey: property.name) else { continue }

            if let managedObject = value as? AkiCopyable {
                copy.setValue(managedObject.unmanaged(), forKey: property.name)
            } else {
                copy.setValue(value, forKey: property.name)
            }

        }

        return copy
    }

}
