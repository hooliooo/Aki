//
//  Aki
//  Copyright (c) 2019 Julio Miguel Alorro
//
//  Licensed under the MIT license. See LICENSE file.
//
//

public protocol AkiCopyable: class {

    /**
     If this instance is a RealmObject, it will return an unmanaged copy of this instance, otherwise returns self
    */
    func unmanaged() -> Self

}
