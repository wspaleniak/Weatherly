//
//  Weather.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 19/11/2026.
//

import Foundation

/// A normalized forecast for one location.
struct Weather: Hashable, Sendable {
    /// Weather conditions at the time of the forecast response.
    struct Current: Hashable, Sendable {
        /// The local timestamp returned by the API.
        let time: String
        /// The air temperature at 2 meters above ground, in degrees Celsius.
        let temperature: Double
        /// The percentage of the sky covered by clouds.
        let cloudCover: Double
        /// The interpreted WMO code for the current conditions.
        let condition: Condition
    }
    
    /// Weather values associated with one hourly timestamp.
    struct Hourly: Hashable, Sendable {
        /// The local timestamp returned by the API.
        let time: String
        /// The air temperature at 2 meters above ground, when available.
        let temperature: Double?
        /// The probability of precipitation for the preceding hour, in percent, when available.
        let precipitationProbability: Double?
    }
    
    /// Weather aggregates associated with one local calendar date.
    struct Daily: Hashable, Sendable {
        /// The local calendar date returned by the API.
        let time: String
        /// The maximum air temperature at 2 meters above ground, when available.
        let maximumTemperature: Double?
        /// The minimum air temperature at 2 meters above ground, when available.
        let minimumTemperature: Double?
        /// The maximum probability of precipitation for the day, in percent, when available.
        let maximumPrecipitationProbability: Double?
        /// The interpreted WMO code for the daily conditions.
        let condition: Condition
    }
    
    /// The time zone resolved for the forecast location, if Foundation recognizes the identifier.
    let timezone: TimeZone?
    /// Weather conditions for the current time.
    let current: Current
    /// Hourly forecast values.
    let hourly: [Hourly]
    /// Daily forecast aggregates.
    let daily: [Daily]
}

// MARK: - Inits

extension Weather {
    /// Creates an app model from a decoded Open-Meteo forecast response.
    ///
    /// - Parameter model: The decoded forecast response.
    init(_ model: Network.Decoding.Weather) {
        self.timezone = TimeZone(identifier: model.timezone)
        self.current = .init(model.current)
        self.hourly = model.hourly.time.enumerated().map { index, time in
            .init(time: time, model: model.hourly, index: index)
        }
        self.daily = model.daily.time.enumerated().map { index, time in
            .init(time: time, model: model.daily, index: index)
        }
    }
}

extension Weather.Current {
    /// Creates current conditions from the decoded API values.
    ///
    /// - Parameter model: The decoded current conditions.
    init(_ model: Network.Decoding.Weather.Current) {
        self.time = model.time
        self.temperature = model.temperature2M
        self.cloudCover = model.cloudCover
        self.condition = .init(rawValue: model.weatherCode ?? -1) ?? .unknown
    }
}

extension Weather.Hourly {
    /// Creates one hourly forecast value from the corresponding API array entries.
    ///
    /// - Parameters:
    ///   - time: The local timestamp for this forecast value.
    ///   - model: The decoded hourly forecast arrays.
    ///   - index: The index shared by the timestamp and each weather value.
    init(time: String, model: Network.Decoding.Weather.Hourly, index: Int) {
        self.time = time
        self.temperature = model.temperature2M.indices.contains(index)
            ? model.temperature2M[index]
            : nil
        self.precipitationProbability = model.precipitationProbability.indices.contains(index)
            ? model.precipitationProbability[index]
            : nil
    }
}

extension Weather.Daily {
    /// Creates one daily forecast value from the corresponding API array entries.
    ///
    /// - Parameters:
    ///   - time: The local calendar date for this forecast value.
    ///   - model: The decoded daily forecast arrays.
    ///   - index: The index shared by the date and each weather value.
    init(time: String, model: Network.Decoding.Weather.Daily, index: Int) {
        self.time = time
        self.maximumTemperature = model.temperature2MMax.indices.contains(index)
            ? model.temperature2MMax[index]
            : nil
        self.minimumTemperature = model.temperature2MMin.indices.contains(index)
            ? model.temperature2MMin[index]
            : nil
        self.maximumPrecipitationProbability = model.precipitationProbabilityMax.indices.contains(index)
            ? model.precipitationProbabilityMax[index]
            : nil
        let weatherCode = model.weatherCode.indices.contains(index)
            ? model.weatherCode[index]
            : nil
        self.condition = .init(rawValue: weatherCode ?? -1) ?? .unknown
    }
}
