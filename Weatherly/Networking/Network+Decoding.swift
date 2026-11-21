//
//  Network+Decoding.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 19/11/2026.
//

import Foundation

extension Network {
    /// Models the response payloads returned by the Open-Meteo APIs.
    enum Decoding {
        
        // MARK: - Search
        
        /// The response returned by the Open-Meteo Geocoding API.
        struct Search: Decodable, Sendable {
            /// A matching location returned by a geocoding search.
            struct City: Decodable, Sendable {
                /// The GeoNames identifier for the location.
                let id: Int
                /// The localized name of the location.
                let name: String
                /// The latitude of the location in the WGS84 coordinate system.
                let latitude: Double
                /// The longitude of the location in the WGS84 coordinate system.
                let longitude: Double
                /// The localized country name, when available.
                let country: String?
                /// The first-level administrative area, when available.
                let admin1: String?
            }
            
            /// Matching locations. The API may omit this key when there are no results.
            let results: [City]?
        }
        
        // MARK: - Weather

        /// The response returned by the Open-Meteo Forecast API.
        struct Weather: Decodable, Sendable {
            /// Current weather conditions for the requested location.
            struct Current: Decodable, Sendable {
                /// The local date and time at which the current conditions apply.
                let time: String
                /// The air temperature at 2 meters above ground.
                let temperature2M: Double
                /// The percentage of the sky covered by clouds.
                let cloudCover: Double
                /// The WMO weather interpretation code, when available.
                let weatherCode: Int?
            }
            
            /// Hourly weather values. Values at the same index correspond to the same time.
            struct Hourly: Decodable, Sendable {
                /// Local timestamps for the hourly forecast values.
                let time: [String]
                /// Air temperatures at 2 meters above ground. An element may be `null` when data is unavailable.
                let temperature2M: [Double?]
                /// Probability of precipitation for each preceding hour, in percent. An element may be `null` when unavailable.
                let precipitationProbability: [Double?]
            }
            
            /// Daily weather aggregates. Values at the same index correspond to the same date.
            struct Daily: Decodable, Sendable {
                /// Local dates for the daily forecast values.
                let time: [String]
                /// Maximum daily air temperatures at 2 meters above ground, when available.
                let temperature2MMax: [Double?]
                /// Minimum daily air temperatures at 2 meters above ground, when available.
                let temperature2MMin: [Double?]
                /// Maximum daily probability of precipitation, in percent, when available.
                let precipitationProbabilityMax: [Double?]
                /// WMO weather interpretation codes for the daily conditions, when available.
                let weatherCode: [Int?]
            }
            
            /// The IANA time zone used for the returned forecast timestamps.
            let timezone: String
            /// Current conditions requested by this app.
            let current: Current
            /// Hourly forecast data requested by this app.
            let hourly: Hourly
            /// Daily forecast data requested by this app.
            let daily: Daily
        }
    }
}

// MARK: - Coding keys

extension Network.Decoding.Weather.Current {
    /// Maps current-condition properties to their Open-Meteo JSON keys.
    private enum CodingKeys: String, CodingKey {
        case time
        case temperature2M = "temperature_2m"
        case cloudCover = "cloud_cover"
        case weatherCode = "weather_code"
    }
}

extension Network.Decoding.Weather.Hourly {
    /// Maps hourly forecast properties to their Open-Meteo JSON keys.
    private enum CodingKeys: String, CodingKey {
        case time
        case temperature2M = "temperature_2m"
        case precipitationProbability = "precipitation_probability"
    }
}

extension Network.Decoding.Weather.Daily {
    /// Maps daily forecast properties to their Open-Meteo JSON keys.
    private enum CodingKeys: String, CodingKey {
        case time
        case temperature2MMax = "temperature_2m_max"
        case temperature2MMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
        case weatherCode = "weather_code"
    }
}
