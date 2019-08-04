//
//  Aki
//  Created by Julio Miguel Alorro on 04.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import class Dispatch.DispatchIO
import class Dispatch.DispatchQueue
import class Foundation.FileManager
import class Foundation.NSError
import struct Dispatch.DispatchData
import struct Dispatch.DispatchQoS
import struct Foundation.Data
import struct Foundation.URL
import os

fileprivate let logger: OSLog = OSLog(subsystem: Constants.subsystem, category: "Write Operation")

/**
 A WriteOperation is an AsyncOperation that represents the business logic of writing Data to the file system.
*/
public final class WriteOperation: AsyncOperation<Result<URL, Error>> {

    private static let queue: DispatchQueue = DispatchQueue(label: "WriteOperation", qos: DispatchQoS.background)

    /**
     Failable initializer.

     - parameters:
        - content            : The content to be written to disk.
        - outputFileName     : The name of the file to be written to.
        - fileExtension      : The extension of the file to be written to.
        - fileManager        : The FileManager instance. The default value is FileManager.default.
        - searchPathDirectory: The FileManager.SearchPathDirectory. The default value is FileManager.SearchPathDirectory.documentDirectory.
    */
    public init?(
        content: WriteOperation.Content,
        outputFileName: String,
        fileExtension: String,
        fileManager: FileManager = FileManager.default,
        searchPathDirectory: FileManager.SearchPathDirectory = FileManager.SearchPathDirectory.documentDirectory
    ) {
        guard let rootURL = fileManager
            .urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
            .first
        else {
            os_log("Could not get root url", log: logger, type: OSLogType.error)
            return nil
        }

        self.content = content

        self.outFileURL = rootURL
            .appendingPathComponent(outputFileName)
            .appendingPathExtension(fileExtension)
        super.init()
    }

    // MARK: Stored Properties

    /**
     The URL of the destination file.
    */
    private let outFileURL: URL

    /**
     The content to be written to the destination file.
    */
    private let content: WriteOperation.Content

    private let highWaterLimit: Int = 1_024 * 1_024

    // MARK: Methods
    public override func main() {

        guard !self.isCancelled else {
            return
        }

        guard let writeIO = DispatchIO(
            type: DispatchIO.StreamType.stream,
            path: self.outFileURL.path,
            oflag: (O_RDWR | O_CREAT | O_APPEND),
            mode: (S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH),
            queue: WriteOperation.queue,
            cleanupHandler: {_ in }
        )
        else {
            self.state = AkiOperation.State.finished
            return
        }

        let dispatchData: DispatchData

        switch self.content {
            case .url(let url):
                do {
                    let data: Data = try Data(contentsOf: url)
                    dispatchData = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> DispatchData in
                        return DispatchData(bytes: pointer)
                    }
                } catch let error {
                    os_log(
                        "Data could not be retrieved from %s with error: %s",
                        log: logger,
                        type: OSLogType.error,
                        error.localizedDescription,
                        url.path
                    )

                    self.state = AkiOperation.State.finished
                    return
                }

            case .data(let data):
                dispatchData = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> DispatchData in
                    return DispatchData(bytes: pointer)
                }
        }

        writeIO.setLimit(highWater: self.highWaterLimit)
        writeIO.write(offset: 0, data: dispatchData, queue: WriteOperation.queue) { [weak self] (isDoneWriting: Bool, _: DispatchData?, writeError: Int32) -> Void in
            guard let s = self else { return }

            guard writeError == 0 else {
                writeIO.close(flags: DispatchIO.CloseFlags.stop)
                os_log("WriteOperation error: %i", log: logger, type: OSLogType.error, writeError)
                s.value = Result.failure(NSError(domain: "DispatchIO Write Error", code: Int(writeError), userInfo: nil))
                s.state = AkiOperation.State.finished
                return
            }

            guard !s.isCancelled else {
                writeIO.close(flags: DispatchIO.CloseFlags.stop)
                os_log("WriteOperation cancelled", log: logger, type: OSLogType.info)
                s.state = AkiOperation.State.finished
                return
            }

            if isDoneWriting {
                s.value = Result.success(s.outFileURL)
                writeIO.close()
                os_log("Done writing to %s", log: logger, type: OSLogType.info, s.outFileURL.path)
                s.state = AkiOperation.State.finished
            }
        }
    }

}

public extension WriteOperation {

    /**
     Represents the information to be written to disk.
    */
    enum Content {

        /**
         The URL of the temporary location of the data to be written to disk.
        */
        case url(URL)

        /**
         The data to be written to disk.
        */
        case data(Data)
    }

}
