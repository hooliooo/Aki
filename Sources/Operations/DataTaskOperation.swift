//
//  Aki
//  Created by Julio Miguel Alorro on 02.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import class Foundation.HTTPURLResponse
import class Foundation.NSError
import class Foundation.URLResponse
import class Foundation.URLSession
import class Foundation.URLSessionDataTask
import struct Foundation.Data
import struct Foundation.URLRequest
import os

fileprivate let logger: OSLog = OSLog(subsystem: Constants.subsystem, category: "DataTaskOperation")

/**
 A DataTaskOperation is an AsyncOperation that represents a URLSessionDataTask created from a URLSession's dataTask(request:completionHandler)
 method.
*/
public final class DataTaskOperation: AsyncOperation<Result<Data, Error>> {

    /**
     The URLSession that creates the URLSessionDataTask. This URLSession instance is not strongly referenced by the DataTaskOperation.
    */
    private unowned let session: URLSession

    /**
     The URLRequest instance used to create the URLSessionDataTask.
    */
    private let urlRequest: URLRequest

    /**
     The callback executed when the HTTP network request finishes.
    */
    private let onComplete: ((Result<Data, Error>) -> Void)?

    /**
     The URLSessionDataTask created by the URLSession and URLRequest.
    */
    private var task: URLSessionDataTask?

    /**
     Initializer.

     - parameters:
        - session   : URLSession instance. The default value is URLSession.shared.
        - urlRequest: The URLRequest instance containing the HTTP network request data.
        - onComplete: The callback executed when the HTTP network request finishes. The default value is nil. If the value is nil,
                      then the result of the HTTP network request is binded to the DataTaskOperation's value property.
    */
    public init(
        session: URLSession = URLSession.shared,
        urlRequest: URLRequest,
        onComplete: ((Result<Data, Error>) -> Void)? = nil
    ) {
        self.session = session
        self.urlRequest = urlRequest
        self.onComplete = onComplete
        super.init()
    }

    public override func main() { // swiftlint:disable:this cyclomatic_complexity
        // swiftlint:disable:previous function_body_length

        os_log("URL: %@", log: logger, type: OSLogType.info, self.urlRequest.url?.absoluteString ?? "No URL")
        os_log("HTTP Method: %@", log: logger, type: OSLogType.info, self.urlRequest.httpMethod ?? "No HTTP Method")
        os_log("HTTP Headers", log: logger, type: OSLogType.info)

        if let headers = self.urlRequest.allHTTPHeaderFields {
            for header in headers {
                os_log("HTTP Header: %@ => %@", log: logger, type: OSLogType.info, header.key, header.value)
            }
        }

        let body: String = {
            if let body = self.urlRequest.httpBody {
                if let value = String(data: body, encoding: String.Encoding.utf8) {
                    return value
                } else {
                    return body.description
                }
            } else {
                return "No body"
            }
        }()

        os_log("Body: %s", log: logger, type: OSLogType.info, body)
        // swiftlint:disable:next line_length
        let onComplete: (Result<Data, Error>) -> Void = { [weak self] (result: Result<Data, Error>) -> Void in
            if let onComplete = self?.onComplete {
                onComplete(result)
            } else {
                self?.set(value: result)
            }
        }

        self.task = self.session.dataTask(with: self.urlRequest) {
            [weak self] (data: Data?, response: URLResponse?, error: Swift.Error?) -> Void in
            // swiftlint:disable:previous closure_parameter_position
            guard let s = self else { return }

            defer { s.state = AkiOperation.State.finished }

            guard !s.isCancelled else { return }

            if let error = error {
                os_log("Error Response: %@", log: logger, type: OSLogType.error, error.localizedDescription)
                onComplete(Result<Data, Error>.failure(error))

            } else if let data = data, let response = response as? HTTPURLResponse {
                os_log("Success Response: %@", log: logger, type: OSLogType.info, response.description)
                onComplete(Result<Data, Error>.success(data))

            } else {
                os_log("Unknown response", log: logger, type: OSLogType.error)
                onComplete(Result<Data, Error>.failure(
                    NSError(domain: "URLSession", code: -1337, userInfo: nil)
                ))
            }
        }
        self.task?.resume()
    }

    public override func cancel() {
        super.cancel()
        self.task?.cancel()
    }
}
