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
