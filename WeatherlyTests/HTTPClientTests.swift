import Foundation
import Testing
@testable import Weatherly

/// Verifies HTTP client URL construction.
struct HTTPClientTests {
    @Test func `when make URL receives a base URL and path it returns the combined URL`() throws {
        let url = try Network.HTTPClient.makeURL(
            from: "https://example.com/v1",
            appendingPath: "/search",
            queryItems: [URLQueryItem(name: "name", value: "New York")]
        )

        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(components.path == "/v1/search")
        #expect(queryItems(for: components)["name"] == "New York")
    }
}
