import Foundation
import SwiftData
@testable import Weatherly

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

/// Creates an isolated in-memory city store for model tests.
/// - Returns: A SwiftData service backed by a new in-memory container.
@MainActor
func makeInMemoryCityDataService() throws -> SwiftDataService<CityDataModel> {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let modelContainer = try ModelContainer(
        for: CityDataModel.self,
        configurations: configuration
    )
    return SwiftDataService(modelContainer: modelContainer)
}

/// Creates a city fixture with sensible defaults for view-model tests.
/// - Parameters:
///   - id: The geocoding identifier for the city.
///   - name: The city name.
///   - isFavorite: Whether the city is marked as a favorite.
///   - lastSearchedAt: The previous search date, if one exists.
/// - Returns: A city using Warsaw coordinates and Polish administrative details.
func makeTestCity(
    id: Int = 756135,
    name: String = "Warszawa",
    isFavorite: Bool = false,
    lastSearchedAt: Date? = nil
) -> City {
    City(
        id: id,
        name: name,
        coordinates: .init(latitude: 52.23, longitude: 21.01),
        country: "Polska",
        administrativeArea: "Mazowieckie",
        isFavorite: isFavorite,
        lastSearchedAt: lastSearchedAt
    )
}

/// Creates a deterministic forecast fixture for view-model tests.
/// - Returns: A forecast containing current, hourly, and daily values.
func makeTestWeather() -> Weather {
    Weather(
        timezone: TimeZone(identifier: "Europe/Warsaw"),
        current: .init(
            time: "2026-11-20T18:30",
            temperature: 3.6,
            cloudCover: 43,
            condition: .mainlyClear
        ),
        hourly: [
            .init(time: "2026-11-20T19:00", temperature: 3.4, precipitationProbability: 12)
        ],
        daily: [
            .init(
                time: "2026-11-20",
                maximumTemperature: 8.4,
                minimumTemperature: 2.0,
                maximumPrecipitationProbability: 100,
                condition: .slightRain
            )
        ]
    )
}

/// Returns configured search and forecast results without making network requests.
struct NetworkServiceStub: Network.Providing {
    /// The result returned by city searches.
    let searchResult: Result<[City], Network.HTTPClient.HTTPError>
    /// The result returned by weather requests.
    let weatherResult: Result<Weather, Network.HTTPClient.HTTPError>

    /// Creates a stub with configurable search and forecast results.
    /// - Parameters:
    ///   - searchResult: The result returned by `search(_:)`.
    ///   - weatherResult: The result returned by `weather(for:)`.
    init(
        searchResult: Result<[City], Network.HTTPClient.HTTPError> = .success([]),
        weatherResult: Result<Weather, Network.HTTPClient.HTTPError> = .success(makeTestWeather())
    ) {
        self.searchResult = searchResult
        self.weatherResult = weatherResult
    }

    /// Returns the configured search result.
    func search(_ query: String) async throws(Network.HTTPClient.HTTPError) -> [City] {
        try searchResult.get()
    }

    /// Returns the configured forecast result.
    func weather(
        for coordinates: City.Coordinates
    ) async throws(Network.HTTPClient.HTTPError) -> Weather {
        try weatherResult.get()
    }
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
