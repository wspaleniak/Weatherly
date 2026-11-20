import Foundation

func queryItems(for components: URLComponents) -> [String: String] {
    Dictionary(
        uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        }
    )
}

func makeStubSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [NetworkStubURLProtocol.self]
    return URLSession(configuration: configuration)
}

final class NetworkStubURLProtocol: URLProtocol, @unchecked Sendable {
    final class Storage: @unchecked Sendable {
        static let shared = Storage()

        private let lock = NSLock()
        private var responseBody = Data()
        private var responseStatusCode = 200
        private var requestURL: String?

        func configure(statusCode: Int, body: Data) {
            lock.lock()
            defer { lock.unlock() }
            responseStatusCode = statusCode
            responseBody = body
            requestURL = nil
        }

        func recordRequest(url: URL?) {
            lock.lock()
            defer { lock.unlock() }
            requestURL = url?.absoluteString
        }

        func response() -> (statusCode: Int, body: Data) {
            lock.lock()
            defer { lock.unlock() }
            return (responseStatusCode, responseBody)
        }

        var lastRequestURL: String? {
            lock.lock()
            defer { lock.unlock() }
            return requestURL
        }

        func reset() {
            configure(statusCode: 200, body: Data())
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

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

    override func stopLoading() {}
}
