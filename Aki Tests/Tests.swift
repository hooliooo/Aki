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

                let groupOp: APIOperation = APIOperation(networkingOp: op, jsonOp: jsonOp)

//                let downloadURL: URL = URL(string: "https://pokeapi.co/api/v2/pokemon/2")!
//                let rootURL: URL = try! FileManager.default.url(for: FileManager.SearchPathDirectory.cachesDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)
//                let cacheURL: URL = rootURL.appendingPathComponent("\(downloadURL.lastPathComponent).json")
//                let downloadOp: DownloadTaskOperation = DownloadTaskOperation(downloadURL: downloadURL, cacheURL: cacheURL)

//                let writeOp: WriteOperation = WriteOperation(
//                    content: WriteOperation.Content.url(cacheURL),
//                    outputFileName: "WriteOp",
//                    fileExtension: "text"
//                )!
//
//                writeOp.addDependency(downloadOp)
                self.queue.addOperation(groupOp)
//                self.queue.addOperations([op, jsonOp, downloadOp, writeOp], waitUntilFinished: false)
                expect(groupOp.value).toEventuallyNot(beNil())
//                expect(jsonOp.value).toEventuallyNot(beNil())
//                expect(downloadOp.value).toEventuallyNot(beNil(), timeout: 10.0, pollInterval: 10.0)

            }
        }
    }

}

public class APIOperation: BatchOperation {

    public init(networkingOp: DataTaskOperation, jsonOp: DeserializationOperation<Pokemon>) {
        self.networkingOp = networkingOp
        self.jsonOp = jsonOp
        jsonOp.addDependency(networkingOp)
        super.init(operations: [networkingOp, jsonOp]) { (queue: OperationQueue) -> Void in
            queue.qualityOfService = .background
            queue.maxConcurrentOperationCount = 1
        }
    }

    private let networkingOp: DataTaskOperation
    private let jsonOp: DeserializationOperation<Pokemon>
}

public struct Pokemon: Decodable {

    // MARK: Stored Properties
    public let id: Int
    public let name: String
    public let height: Int
    public let weight: Int

}
