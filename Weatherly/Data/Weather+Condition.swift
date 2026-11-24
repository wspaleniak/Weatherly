//
//  Weather+Condition.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 20/11/2026.
//

import Foundation

extension Weather {
    /// A WMO weather interpretation code returned by Open-Meteo.
    enum Condition: Int, CaseIterable, Hashable, Sendable {
        /// An unrecognized or unavailable weather code.
        case unknown = -1
        /// Clear sky.
        case clearSky = 0
        /// Mainly clear conditions.
        case mainlyClear = 1
        /// Partly cloudy conditions.
        case partlyCloudy = 2
        /// Overcast conditions.
        case overcast = 3
        /// Fog.
        case fog = 45
        /// Depositing rime fog.
        case depositingRimeFog = 48
        /// Light drizzle.
        case lightDrizzle = 51
        /// Moderate drizzle.
        case moderateDrizzle = 53
        /// Dense drizzle.
        case denseDrizzle = 55
        /// Light freezing drizzle.
        case lightFreezingDrizzle = 56
        /// Dense freezing drizzle.
        case denseFreezingDrizzle = 57
        /// Slight rain.
        case slightRain = 61
        /// Moderate rain.
        case moderateRain = 63
        /// Heavy rain.
        case heavyRain = 65
        /// Light freezing rain.
        case lightFreezingRain = 66
        /// Heavy freezing rain.
        case heavyFreezingRain = 67
        /// Slight snowfall.
        case slightSnowfall = 71
        /// Moderate snowfall.
        case moderateSnowfall = 73
        /// Heavy snowfall.
        case heavySnowfall = 75
        /// Snow grains.
        case snowGrains = 77
        /// Slight rain showers.
        case slightRainShowers = 80
        /// Moderate rain showers.
        case moderateRainShowers = 81
        /// Violent rain showers.
        case violentRainShowers = 82
        /// Slight snow showers.
        case slightSnowShowers = 85
        /// Heavy snow showers.
        case heavySnowShowers = 86
        /// Thunderstorm.
        case thunderstorm = 95
        /// Thunderstorm with slight hail.
        case thunderstormWithSlightHail = 96
        /// Heavy thunderstorm.
        case heavyThunderstorm = 97
        /// Thunderstorm with heavy hail.
        case thunderstormWithHeavyHail = 99
    }
}

// MARK: - Descriptions and images

extension Weather.Condition {
    /// A localized description of this weather condition.
    var localizedDescription: LocalizedStringResource {
        switch self {
        case .unknown: "Weather.Condition.unknown"
        case .clearSky: "Weather.Condition.clearSky"
        case .mainlyClear: "Weather.Condition.mainlyClear"
        case .partlyCloudy: "Weather.Condition.partlyCloudy"
        case .overcast: "Weather.Condition.overcast"
        case .fog, .depositingRimeFog: "Weather.Condition.fog"
        case .lightDrizzle, .moderateDrizzle, .denseDrizzle: "Weather.Condition.drizzle"
        case .lightFreezingDrizzle, .denseFreezingDrizzle: "Weather.Condition.freezingDrizzle"
        case .slightRain, .moderateRain, .heavyRain: "Weather.Condition.rain"
        case .lightFreezingRain, .heavyFreezingRain: "Weather.Condition.freezingRain"
        case .slightSnowfall, .moderateSnowfall, .heavySnowfall, .snowGrains: "Weather.Condition.snow"
        case .slightRainShowers, .moderateRainShowers, .violentRainShowers: "Weather.Condition.rainShowers"
        case .slightSnowShowers, .heavySnowShowers: "Weather.Condition.snowShowers"
        case .thunderstorm, .thunderstormWithSlightHail,
             .heavyThunderstorm, .thunderstormWithHeavyHail: "Weather.Condition.thunderstorm"
        }
    }

    /// The SF Symbols name that represents this weather condition.
    var systemImage: String {
        switch self {
        case .unknown: "questionmark.circle"
        case .clearSky, .mainlyClear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .overcast: "cloud.fill"
        case .fog, .depositingRimeFog: "cloud.fog.fill"
        case .lightDrizzle, .moderateDrizzle, .denseDrizzle: "cloud.drizzle.fill"
        case .lightFreezingDrizzle, .denseFreezingDrizzle,
             .lightFreezingRain, .heavyFreezingRain: "cloud.sleet.fill"
        case .slightRain, .moderateRain, .heavyRain,
             .slightRainShowers, .moderateRainShowers, .violentRainShowers: "cloud.rain.fill"
        case .slightSnowfall, .moderateSnowfall, .heavySnowfall,
             .snowGrains, .slightSnowShowers, .heavySnowShowers: "cloud.snow.fill"
        case .thunderstorm, .thunderstormWithSlightHail,
             .heavyThunderstorm, .thunderstormWithHeavyHail: "cloud.bolt.rain.fill"
        }
    }
}
