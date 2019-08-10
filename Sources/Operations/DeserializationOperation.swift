//
//  Aki
//  Created by Julio Miguel Alorro on 02.08.19.
//  Licensed under the MIT license. See LICENSE file
//

import class Foundation.JSONDecoder
import class Foundation.Operation
import os

fileprivate let logger: OSLog = OSLog(subsystem: Constants.subsystem, category: "Deserialization Operation")
fileprivate let decoder: JSONDecoder = JSONDecoder()

/**
 DeserializationOperation is a synchronous AkiOperation that represents the deserialization logic of the data derived
 from a DataTaskOperation dependency.
*/
public final class DeserializationOperation<T: Decodable>: AkiOperation<Result<T, DecodingError>> {


    public init(onComplete: @escaping (Result<T, DecodingError>) -> Void = { _ in }) {
        self.onComplete = onComplete
        super.init()
    }

    // MARK: Stored Properties
    private let onComplete: (Result<T, DecodingError>) -> Void

    public override func main() {
        defer { self.state = AkiOperation.State.finished }
        guard !self.isCancelled else { return }

        guard
            let value = self.dependencies.lazy
                .compactMap({ $0 as? DataTaskOperation })
                .first?
                .value,
            case let Result.success(data) = value
        else {
            os_log("No DataTaskOperation or no success value", log: logger, type: OSLogType.error)
            return
        }

        guard !self.isCancelled else { return }

        do {
            let value: T = try decoder.decode(T.self, from: data)
            os_log("Successfully deserialized %s: %s", log: logger, type: OSLogType.error, "\(T.self)", "\(value)")
            let result: Result<T, DecodingError> = Result.success(value)
            self.value = result
            self.onComplete(result)
        } catch let error as DecodingError {
            os_log("Deserialization Error: %s", log: logger, type: OSLogType.error, error.localizedDescription)
            let result: Result<T, DecodingError> = Result.failure(error)
            self.value = result
            self.onComplete(result)
        } catch {
            os_log("Unknown Error: %s", log: logger, type: OSLogType.error, error.localizedDescription)
        }
    }
}
