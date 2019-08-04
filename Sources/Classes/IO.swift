//
//  Aki
//  Created by Julio Miguel Alorro on 04.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import Foundation

public class IO {

    // MARK: Static Properties
    private static let queue: DispatchQueue = DispatchQueue(label: "IO", qos: DispatchQoS.background)

    public init(outputFileName: String) {
        let rootURL: URL = try! FileManager.default.url(
            for: FileManager.SearchPathDirectory.applicationDirectory,
            in: FileManager.SearchPathDomainMask.userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let filePath: URL = rootURL
            .appendingPathComponent(outputFileName)
            .appendingPathExtension("txt")

        self.outputFilePath = filePath.path
    }

    // MARK: Stored Properties
    private let outputFilePath: String
    private let highWaterLimit: Int = 1024 * 1024

    public func writeData(from files: [URL]) {

        Data("A string".utf8).withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> DispatchData in
            DispatchData(bytes: pointer)
        }

        let writeIO: DispatchIO = DispatchIO(
            type: .stream,
            path: self.outputFilePath,
            oflag: (O_RDWR | O_CREAT | O_APPEND),
            mode: (S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH),
            queue: IO.queue,
            cleanupHandler: {_ in }
        )!
        writeIO.setLimit(highWater: self.highWaterLimit)
        let group: DispatchGroup = DispatchGroup()

        for file in files {
            group.enter()

            let readIO: DispatchIO = DispatchIO(
                type: .stream,
                path: file.path,
                oflag: O_RDONLY,
                mode: 0,
                queue: IO.queue,
                cleanupHandler: {_ in }
            )!

            readIO.setLimit(highWater: self.highWaterLimit)
            readIO.read(offset: 0, length: Int.max, queue: IO.queue) { (isDone: Bool, data: DispatchData?, error: Int32) -> Void in
                guard error == 0 else {
                    writeIO.close()
                    group.leave()
                    return
                }

                if let data = data {
                    let bytesRead = data.count
                    print("Reading")
                    if bytesRead > 0 {
                        group.enter()
                        writeIO.write(offset: 0, data: data, queue: IO.queue) { (isDoneWriting: Bool, data: DispatchData?, writeError: Int32) -> Void in
                            print("Writing")
                            guard writeError == 0 else {
                                readIO.close(flags: DispatchIO.CloseFlags.stop)
                                group.leave()
                                return
                            }

                            if isDoneWriting {
                                print("Writing Done")
                                group.leave()
                            }
                        }
                    }
                }

                if isDone {
                    readIO.close()
                    if file == files.last {
                        writeIO.close()
                    }

                    group.leave()
                }
            }
        }
        print("Done write to \(self.outputFilePath)")
    }
}
