import Foundation
import Testing
@testable import Weatherly

/// Verifies Open-Meteo search and forecast requests and response mapping.
@Suite(.serialized)
struct ServiceTests {
    @Test func `when search receives a query with whitespace it trims the query and maps cities`() async throws {
        NetworkStubURLProtocol.Storage.shared.configure(
            statusCode: 200,
            body: Data(
                #"{"results":[{"id":756135,"name":"Warszawa","latitude":52.23,"longitude":21.01,"country":"Polska","admin1":"Mazowieckie"}]}"#.utf8
            )
        )
        defer { NetworkStubURLProtocol.Storage.shared.reset() }

        let service = Network.Service(session: makeStubSession())
        let cities = try await service.search("  Warszawa  ")

        #expect(cities.count == 1)
        #expect(cities[0].id == 756135)
        #expect(cities[0].name == "Warszawa")
        #expect(cities[0].coordinates.latitude == 52.23)
        #expect(cities[0].coordinates.longitude == 21.01)
        #expect(cities[0].country == "Polska")
        #expect(cities[0].administrativeArea == "Mazowieckie")

        let requestURL = try #require(NetworkStubURLProtocol.Storage.shared.lastRequestURL)
        let components = try #require(URLComponents(string: requestURL))
        #expect(components.path == "/v1/search")
        #expect(queryItems(for: components)["name"] == "Warszawa")
        #expect(queryItems(for: components)["count"] == "10")
        #expect(queryItems(for: components)["language"] == "pl")
        #expect(queryItems(for: components)["format"] == "json")
    }

    @Test func `when search receives a blank query it returns no results without sending a request`() async throws {
        NetworkStubURLProtocol.Storage.shared.reset()
        defer { NetworkStubURLProtocol.Storage.shared.reset() }

        let service = Network.Service(session: makeStubSession())
        let cities = try await service.search(" \n ")

        #expect(cities.isEmpty)
        #expect(NetworkStubURLProtocol.Storage.shared.lastRequestURL == nil)
    }

    @Test func `when search response omits results it returns an empty array`() async throws {
        NetworkStubURLProtocol.Storage.shared.configure(statusCode: 200, body: Data("{}".utf8))
        defer { NetworkStubURLProtocol.Storage.shared.reset() }

        let service = Network.Service(session: makeStubSession())
        let cities = try await service.search("Atlantis")

        #expect(cities.isEmpty)
    }

    @Test func `when search receives a server error it reports the message and status code`() async {
        NetworkStubURLProtocol.Storage.shared.configure(
            statusCode: 429,
            body: Data(#"{"reason":"Too many requests"}"#.utf8)
        )
        defer { NetworkStubURLProtocol.Storage.shared.reset() }

        let service = Network.Service(session: makeStubSession())

        do {
            _ = try await service.search("Warszawa")
            Issue.record("Expected the service to report the server error.")
        } catch let error {
            guard case let .server(message, statusCode) = error else {
                Issue.record("Expected a server error, received \(error).")
                return
            }
            #expect(message == "Too many requests")
            #expect(statusCode == 429)
        }
    }

    @Test func `when weather receives coordinates it requests and maps the forecast`() async throws {
        NetworkStubURLProtocol.Storage.shared.configure(
            statusCode: 200,
            body: Data(
                #"{"timezone":"Europe/Warsaw","current":{"time":"2026-11-20T18:30","temperature_2m":3.6,"cloud_cover":43,"weather_code":1},"hourly":{"time":["2026-11-20T18:00","2026-11-20T19:00"],"temperature_2m":[3.8,null],"precipitation_probability":[0,25]},"daily":{"time":["2026-11-20","2026-11-21"],"temperature_2m_max":[8.4,3.7],"temperature_2m_min":[2.0,1.1],"precipitation_probability_max":[100,12],"weather_code":[61,51]}}"#.utf8
            )
        )
        defer { NetworkStubURLProtocol.Storage.shared.reset() }

        let service = Network.Service(session: makeStubSession())
        let weather = try await service.weather(
            for: City.Coordinates(latitude: 52.23, longitude: 21.01)
        )

        #expect(weather.timezone == TimeZone(identifier: "Europe/Warsaw"))
        #expect(weather.current.time == "2026-11-20T18:30")
        #expect(weather.current.temperature == 3.6)
        #expect(weather.current.cloudCover == 43)
        #expect(weather.current.condition == .mainlyClear)
        #expect(weather.hourly.count == 2)
        #expect(weather.hourly[0].temperature == 3.8)
        #expect(weather.hourly[1].temperature == nil)
        #expect(weather.hourly[1].precipitationProbability == 25)
        #expect(weather.daily.count == 2)
        #expect(weather.daily[0].maximumTemperature == 8.4)
        #expect(weather.daily[0].minimumTemperature == 2.0)
        #expect(weather.daily[0].maximumPrecipitationProbability == 100)
        #expect(weather.daily[0].condition == .slightRain)

        let requestURL = try #require(NetworkStubURLProtocol.Storage.shared.lastRequestURL)
        let components = try #require(URLComponents(string: requestURL))
        let query = queryItems(for: components)
        #expect(components.path == "/v1/forecast")
        #expect(query["latitude"] == "52.23")
        #expect(query["longitude"] == "21.01")
        #expect(query["forecast_hours"] == "24")
        #expect(query["forecast_days"] == "7")
        #expect(query["timezone"] == "auto")
        #expect(query["temperature_unit"] == "celsius")
        #expect(query["current"] == "temperature_2m,cloud_cover,weather_code")
        #expect(query["hourly"] == "temperature_2m,precipitation_probability")
        #expect(query["daily"] == "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code")
    }

    @Test func `when weather response is incomplete it reports a decoding error`() async {
        NetworkStubURLProtocol.Storage.shared.configure(
            statusCode: 200,
            body: Data(#"{"timezone":"Europe/Warsaw"}"#.utf8)
        )
        defer { NetworkStubURLProtocol.Storage.shared.reset() }

        let service = Network.Service(session: makeStubSession())

        do {
            _ = try await service.weather(
                for: City.Coordinates(latitude: 52.23, longitude: 21.01)
            )
            Issue.record("Expected the service to report a decoding error.")
        } catch let error {
            guard case .decoding = error else {
                Issue.record("Expected a decoding error, received \(error).")
                return
            }
        }
    }
}
