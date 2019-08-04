//
//  Aki Tests
//  Copyright (c) 2019 Julio Miguel Alorro
//
//  Licensed under the MIT license. See LICENSE file.
//
//

import Quick
import Nimble
@testable import Aki

class AkiCopyableTests: QuickSpec {

    private let queue: OperationQueue = OperationQueue()

    override func spec() {
        self.queue.qualityOfService = .background
        describe("DataTaskOperation") {
            it("should work") {
                let url: URL = URL(string: "https://pokeapi.co/api/v2/pokemon/1")!
                let op: DataTaskOperation = DataTaskOperation(session: URLSession.shared, urlRequest: URLRequest(url: url))
                let jsonOp: DeserializationOperation<Pokemon> = DeserializationOperation<Pokemon>()
                jsonOp.addDependency(op)

                let downloadURL: URL = URL(string: "https://pokeapi.co/api/v2/pokemon/2")!
                let rootURL: URL = try! FileManager.default.url(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)
                let cacheURL: URL = rootURL.appendingPathComponent("\(downloadURL.lastPathComponent).json")
                let downloadOp: DownloadOperation = DownloadOperation(downloadURL: downloadURL, cacheURL: cacheURL)

                let writeOp: WriteOperation = WriteOperation(
                    content: WriteOperation.Content.url(cacheURL),
                    outputFileName: "WriteOp",
                    fileExtension: "text"
                )!

                writeOp.addDependency(downloadOp)

                self.queue.addOperations([op, jsonOp, downloadOp, writeOp], waitUntilFinished: false)
                expect(op.value).toEventuallyNot(beNil())
                expect(jsonOp.value).toEventuallyNot(beNil())
                expect(downloadOp.value).toEventuallyNot(beNil(), timeout: 10.0, pollInterval: 10.0)

            }
        }
    }

}

public struct Pokemon: Decodable {

    // MARK: Stored Properties
    public let id: Int
    public let name: String
    public let height: Int
    public let weight: Int

}
