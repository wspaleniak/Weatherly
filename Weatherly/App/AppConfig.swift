//
//  AppConfig.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 20/11/2026.
//

import Foundation

/// Shared configuration values used by the app.
enum AppConfig {
    
    // MARK: - URL
    
    /// Base URLs for remote services.
    enum URL {
        /// The base URL for Open-Meteo's Geocoding API.
        static let geocodingBase = "https://geocoding-api.open-meteo.com/v1"
        /// The base URL for Open-Meteo's Forecast API.
        static let forecastBase = "https://api.open-meteo.com/v1"
    }
}
