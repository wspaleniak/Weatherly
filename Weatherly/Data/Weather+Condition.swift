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
        case unknown = -1
        case clearSky = 0
        case mainlyClear = 1
        case partlyCloudy = 2
        case overcast = 3
        case fog = 45
        case depositingRimeFog = 48
        case lightDrizzle = 51
        case moderateDrizzle = 53
        case denseDrizzle = 55
        case lightFreezingDrizzle = 56
        case denseFreezingDrizzle = 57
        case slightRain = 61
        case moderateRain = 63
        case heavyRain = 65
        case lightFreezingRain = 66
        case heavyFreezingRain = 67
        case slightSnowfall = 71
        case moderateSnowfall = 73
        case heavySnowfall = 75
        case snowGrains = 77
        case slightRainShowers = 80
        case moderateRainShowers = 81
        case violentRainShowers = 82
        case slightSnowShowers = 85
        case heavySnowShowers = 86
        case thunderstorm = 95
        case thunderstormWithSlightHail = 96
        case heavyThunderstorm = 97
        case thunderstormWithHeavyHail = 99
    }
}

// MARK: - Description

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
