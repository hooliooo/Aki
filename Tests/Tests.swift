//
//  VillanelleTests.swift
//  VillanelleTests
//
//  Created by Julio Miguel Alorro on 11/13/18.
//  Copyright © 2018 Julio Alorro Software Development, Inc. All rights reserved.
//

import XCTest
@testable import Aki
import RealmSwift

class Tests: XCTestCase {

    let realmConfiguration: Realm.Configuration = {
        let configuration: Realm.Configuration = Realm.Configuration(inMemoryIdentifier: "Test.Realm")
        Realm.Configuration.defaultConfiguration = configuration
        return configuration
    }()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUnmanagedFunctionality() {

        let a: A = A()

        let bs: [B] = Array(1...10)
            .map { $0.description }
            .map { B(value: ["name": $0] )}

        let cs: [C] = Array(1...10)
            .map { $0.description }
            .map { C(value: ["name": $0] )}

        bs[0].cs.append(objectsIn: cs)
        a.bs.append(objectsIn: bs)

        let realm: Realm = try! Realm()
        try! realm.write {
            realm.add(a)
        }

        let copy: A = a.unmanaged()

        XCTAssert(copy.realm == nil)

        let innerElementsNotManaged: Bool = copy.bs
            .map { $0.realm == nil }
            .contains(false) == false

        let innerInnerElementsNotManaged: Bool = copy.bs
            .flatMap { $0.cs }
            .map { $0.realm == nil }
            .contains(false) == false

        XCTAssert(innerElementsNotManaged)
        XCTAssertTrue(innerInnerElementsNotManaged)

        let check: [Bool] = copy.bs
            .compactMap {
                $0.a.first?.id
            }
            .map {
                copy.id == $0
            }

        XCTAssertFalse(check.contains(false))



    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

class A: Object {
    @objc dynamic var id: String = UUID().uuidString
    let bs: List<B> = List<B>()

    public override static func primaryKey() -> String? {
        return "id"
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? A else { return false }

        return self.id == object.id
    }
}

class B: Object {
    @objc dynamic var name: String = ""
    let a: LinkingObjects<A> = LinkingObjects(fromType: A.self, property: "bs")
    let cs: List<C> = List<C>()
}

class C: Object {
    @objc dynamic var name: String = "C"
    let b: LinkingObjects<B> = LinkingObjects(fromType: B.self, property: "cs")
}
