//
//  Network+Service.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 17/11/2026.
//

import Foundation

extension Network {
    
    // MARK: - Providing
    
    /// Defines the operations available from the app's weather data service.
    protocol Providing: Sendable {
        /// Searches for cities matching the supplied name.
        ///
        /// - Parameter query: The city name to search for.
        /// - Returns: Matching cities, or an empty array when there are no matches.
        /// - Throws: `HTTPClient.HTTPError` if the search request fails or its response cannot be decoded.
        func search(_ query: String) async throws(HTTPClient.HTTPError) -> [City]

        /// Retrieves current conditions and forecasts for the specified coordinates.
        ///
        /// - Parameter coordinates: The geographic coordinates for the forecast.
        /// - Returns: The normalized weather forecast.
        /// - Throws: `HTTPClient.HTTPError` if the forecast request fails or its response cannot be decoded.
        func weather(for coordinates: City.Coordinates) async throws(HTTPClient.HTTPError) -> Weather
    }
    
    // MARK: - Service

    /// Performs location searches and retrieves weather forecasts from Open-Meteo.
    struct Service: Providing {
        private let session: URLSession

        /// Creates the service with the URL session used for requests.
        ///
        /// - Parameter session: The session used to execute requests. Defaults to `URLSession.shared`.
        init(session: URLSession = .shared) {
            self.session = session
        }

        /// Searches for cities matching the supplied name.
        ///
        /// The search term is trimmed before the Geocoding API request. Results are
        /// localized to Polish and limited to ten locations.
        /// - Parameter query: The city name to search for.
        /// - Returns: Matching cities, or an empty array for a blank query or no matches.
        /// - Throws: `HTTPClient.HTTPError` if request creation, transfer, response
        ///   validation, or decoding fails.
        func search(_ query: String) async throws(HTTPClient.HTTPError) -> [City] {
            let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return [] }
            
            let queryItems: [URLQueryItem] = [
                .init(name: "name", value: query),
                .init(name: "count", value: "10"),
                .init(name: "language", value: "pl"),
                .init(name: "format", value: "json")
            ]
            let url = try HTTPClient.makeURL(
                from: AppConfig.URL.geocodingBase,
                appendingPath: "/search",
                queryItems: queryItems
            )
            let request = HTTPClient.makeRequest(for: url)
            let (data, response) = try await HTTPClient.data(for: request, using: session)
            try HTTPClient.handle(data: data, response: response)
            let search = try HTTPClient.decode(data, as: Decoding.Search.self)
            
            guard let searchResults = search.results else { return [] }
            return searchResults.map(City.init)
        }
        
        /// Retrieves current conditions and forecasts for the specified coordinates.
        ///
        /// The response includes current conditions, 24 hours of hourly data, and
        /// seven days of daily data in the location's time zone, with temperatures
        /// requested in Celsius.
        /// - Parameter coordinates: The geographic coordinates for the forecast.
        /// - Returns: The normalized weather forecast.
        /// - Throws: `HTTPClient.HTTPError` if request creation, transfer, response
        ///   validation, or decoding fails.
        func weather(for coordinates: City.Coordinates) async throws(HTTPClient.HTTPError) -> Weather {
            let queryItems: [URLQueryItem] = [
                .init(name: "latitude", value: String(coordinates.latitude)),
                .init(name: "longitude", value: String(coordinates.longitude)),
                .init(name: "current", value: "temperature_2m,cloud_cover,weather_code"),
                .init(name: "hourly", value: "temperature_2m,precipitation_probability"),
                .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code"),
                .init(name: "forecast_hours", value: "24"),
                .init(name: "forecast_days", value: "7"),
                .init(name: "timezone", value: "auto"),
                .init(name: "temperature_unit", value: "celsius")
            ]
            let url = try HTTPClient.makeURL(
                from: AppConfig.URL.forecastBase,
                appendingPath: "/forecast",
                queryItems: queryItems
            )
            let request = HTTPClient.makeRequest(for: url)
            let (data, response) = try await HTTPClient.data(for: request, using: session)
            try HTTPClient.handle(data: data, response: response)

            let weather = try HTTPClient.decode(data, as: Decoding.Weather.self)
            return Weather(weather)
        }
    }
}
