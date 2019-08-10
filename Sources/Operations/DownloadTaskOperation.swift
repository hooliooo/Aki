//
//  Aki
//  Created by Julio Miguel Alorro on 03.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import class Foundation.FileManager
import class Foundation.HTTPURLResponse
import class Foundation.URLResponse
import class Foundation.URLSession
import class Foundation.URLSessionDownloadTask
import struct Foundation.URL
import Foundation
import os

fileprivate let logger: OSLog = OSLog(subsystem: Constants.subsystem, category: "DownloadTaskOperation")

/**
 A DownloadTaskOperation is an AsyncOperation that represents a URLSessionDownloadTask created from a URLSession's
 downloadTask(request:completionHandler) method.
*/
public final class DownloadTaskOperation: AsyncOperation<Result<URL, Error>> {

    /**
     Initializer.

     - parameters:
        - urlRequest : The URLRequest instance containing the HTTP network request data.
        - cacheURL   : The URL of the location where the downloaded data will be stored.
        - session    : URLSession instance. The default value is URLSession.shared.
        - fileManager: The FileManager instance. The default value is FileManager.default.
    */
    public init(
        urlRequest: URLRequest,
        cacheURL: URL,
        session: URLSession = URLSession.shared,
        fileManager: FileManager = FileManager.default
    ) {
        self.urlRequest = urlRequest
        self.cacheURL = cacheURL
        self.session = session
        self.fileManager = fileManager
        super.init()
    }

    /**
     Initializer.

     - parameters:
         - downloadURL: The URL of the data to be downloaded.
         - cacheURL   : The URL of the location where the downloaded data will be stored.
         - session    : URLSession instance. The default value is URLSession.shared.
         - fileManager: The FileManager instance. The default value is FileManager.default.
    */
    public convenience init(
        downloadURL: URL,
        cacheURL: URL,
        session: URLSession = URLSession.shared,
        fileManager: FileManager = FileManager.default
    ) {
        self.init(urlRequest: URLRequest(url: downloadURL), cacheURL: cacheURL, session: session, fileManager: fileManager)
    }

    /**
     The URLRequest instance used to create the URLSessionDownloadTask.
    */
    public let urlRequest: URLRequest

    /**
     The URL of the location where the downloaded data will be stored.
    */
    public let cacheURL: URL

    /**
     The URLSession that creates the URLSessionDownloadTask. This URLSession instance is not strongly referenced by the DownloadTaskOperation.
    */
    private unowned let session: URLSession

    /**
     The FileManager that handles the file logic associated with the download.
    */
    private unowned let fileManager: FileManager

    /**
     The URLSessionDownloadTask created by the URLSession and URLRequest.
    */
    private var task: URLSessionDownloadTask?

    public override func main() {
        self.task = self.session.downloadTask(with: self.urlRequest) {
            [weak self] (url: URL?, response: URLResponse?, error: Error?) -> Void in
            // swiftlint:disable:previous closure_parameter_position
            guard let s = self else { return }

            defer { s.state = AkiOperation.State.finished }

            guard !s.isCancelled else { return }

            if let error = error {
                os_log("Error Response: %@", log: logger, type: OSLogType.error, error.localizedDescription)
                self?.set(value: Result.failure(error))
            } else if let url = url, let response = response as? HTTPURLResponse {
                os_log("Success Response: %@", log: logger, type: OSLogType.info, response.description)

                try? s.fileManager.removeItem(at: s.cacheURL)

                do {
                    try s.fileManager.moveItem(at: url, to: s.cacheURL)
                    os_log(
                        "Downloaded file moved from %s to %s",
                        log: logger,
                        type: OSLogType.info,
                        url.absoluteString,
                        s.cacheURL.absoluteString
                    )
                    self?.set(value: Result.success(s.cacheURL))
                } catch let error {
                    os_log(
                        "Could not move file at %s to %s. because %s",
                        log: logger,
                        type: OSLogType.error,
                        url.absoluteString,
                        s.cacheURL.absoluteString,
                        error.localizedDescription
                    )
                    self?.set(value: Result.failure(error))
                }

            } else {
                os_log("Unknown response", log: logger, type: OSLogType.error)
            }
        }

        self.task?.resume()
    }

    public override func cancel() {
        super.cancel()
        self.task?.cancel()
    }
}
