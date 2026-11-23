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
    
    // MARK: - Spacing
    
    /// Standard spacing values used between elements in the interface.
    enum Spacing {
        /// A compact spacing value for closely related elements.
        static let spacing_05: CGFloat = 6.0
        /// A standard spacing value for related groups of elements.
        static let spacing_1: CGFloat = 12.0
    }
    
    // MARK: - Size
    
    /// Standard dimensions used to size interface elements.
    enum Size {
        /// A small size for compact controls and labels.
        static let small: CGFloat = 32.0
        /// A medium size for prominent symbols and values.
        static let medium: CGFloat = 48.0
        /// A large size for primary values and visual elements.
        static let large: CGFloat = 64.0
    }
}
