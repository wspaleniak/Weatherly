//
//  CityDataModel.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 21/11/2026.
//

import Foundation
import SwiftData

/// Stores a city that can appear in favorites or in recent searches.
@Model
final class CityDataModel {
    /// The stable identifier returned by Open-Meteo's geocoding API.
    @Attribute(.unique) var id: Int
    /// The localized name of the city.
    var name: String
    /// The city's latitude in decimal degrees.
    var latitude: Double
    /// The city's longitude in decimal degrees.
    var longitude: Double
    /// The localized country name, when the API provides one.
    var country: String?
    /// The first-level administrative area, when the API provides one.
    var administrativeArea: String?
    /// Whether the city is included in the user's favorites.
    var isFavorite: Bool
    /// The most recent time the user selected this city from search results.
    var lastSearchedAt: Date
    
    /// Creates a persisted city from the app's city value.
    /// - Parameter city: The city whose data and local state should be stored.
    init(city: City, lastSearchedAt: Date) {
        self.id = city.id
        self.name = city.name
        self.latitude = city.coordinates.latitude
        self.longitude = city.coordinates.longitude
        self.country = city.country
        self.administrativeArea = city.administrativeArea
        self.isFavorite = city.isFavorite
        self.lastSearchedAt = lastSearchedAt
    }
}
