import Foundation

/// Converts URL query items to a dictionary for concise request assertions.
///
/// Query items without values are omitted. Test requests use unique query names.
/// - Parameter components: The URL components whose query should be inspected.
/// - Returns: Query names and their associated values.
func queryItems(for components: URLComponents) -> [String: String] {
    Dictionary(
        uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        }
    )
}

/// Creates an ephemeral URL session that routes requests through the test stub.
/// - Returns: A session configured with ``NetworkStubURLProtocol``.
func makeStubSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [NetworkStubURLProtocol.self]
    return URLSession(configuration: configuration)
}

/// Intercepts URL requests and returns a configurable response without network access.
final class NetworkStubURLProtocol: URLProtocol, @unchecked Sendable {
    /// Thread-safe response and request storage shared by the stub protocol instances.
    final class Storage: @unchecked Sendable {
        /// The shared storage used by each stub protocol instance.
        static let shared = Storage()

        /// Protects the configured response and request URL from concurrent access.
        private let lock = NSLock()
        /// The response body returned by the next intercepted request.
        private var responseBody = Data()
        /// The HTTP status returned by the next intercepted request.
        private var responseStatusCode = 200
        /// The URL of the most recently intercepted request.
        private var requestURL: String?

        /// Sets the response returned for the next intercepted request.
        /// - Parameters:
        ///   - statusCode: The HTTP status code to return.
        ///   - body: The response body data.
        func configure(statusCode: Int, body: Data) {
            lock.lock()
            defer { lock.unlock() }
            responseStatusCode = statusCode
            responseBody = body
            requestURL = nil
        }

        /// Records the URL of the intercepted request.
        /// - Parameter url: The intercepted request URL, if present.
        func recordRequest(url: URL?) {
            lock.lock()
            defer { lock.unlock() }
            requestURL = url?.absoluteString
        }

        /// Returns a snapshot of the configured HTTP response.
        /// - Returns: The response status code and body.
        func response() -> (statusCode: Int, body: Data) {
            lock.lock()
            defer { lock.unlock() }
            return (responseStatusCode, responseBody)
        }

        /// The URL of the most recently intercepted request.
        var lastRequestURL: String? {
            lock.lock()
            defer { lock.unlock() }
            return requestURL
        }

        /// Restores the storage to an empty successful response state.
        func reset() {
            configure(statusCode: 200, body: Data())
        }
    }

    /// Allows the stub protocol to intercept any request.
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    /// Returns the request unchanged for URL loading.
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Sends the configured response to the URL loading system's client.
    override func startLoading() {
        Storage.shared.recordRequest(url: request.url)
        let response = Storage.shared.response()

        guard let url = request.url,
              let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: response.statusCode,
                httpVersion: nil,
                headerFields: nil
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    /// Does nothing because the stub has no asynchronous transfer to cancel.
    override func stopLoading() {}
}
