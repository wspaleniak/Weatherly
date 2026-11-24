//
//  City.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 20/11/2026.
//

import Foundation

/// A city used by the app, including its local favorite and search state.
struct City: Identifiable, Hashable, Sendable {
    /// The geographic coordinates of the city in decimal degrees.
    struct Coordinates: Hashable, Sendable {
        /// The latitude of the city.
        let latitude: Double
        /// The longitude of the city.
        let longitude: Double
    }
    
    /// The unique identifier returned by the geocoding service.
    let id: Int
    /// The localized name of the city.
    let name: String
    /// The geographic coordinates of the city.
    let coordinates: Coordinates
    /// The localized country name, if provided by the service.
    let country: String?
    /// The first-level administrative area, if provided by the service.
    let administrativeArea: String?
    /// Whether the city is included in the user's favorites.
    var isFavorite: Bool
    /// The most recent time the user selected this city from search results.
    var lastSearchedAt: Date?
}

// MARK: - Init from server

extension City {
    /// Creates a city model from a geocoding response.
    ///
    /// Local state starts with `isFavorite` set to `false` and
    /// `lastSearchedAt` set to `nil`.
    /// - Parameter model: The decoded city returned by the geocoding API.
    init(_ model: Network.Decoding.Search.City) {
        self.id = model.id
        self.name = model.name
        self.coordinates = .init(latitude: model.latitude, longitude: model.longitude)
        self.country = model.country
        self.administrativeArea = model.admin1
        self.isFavorite = false
        self.lastSearchedAt = nil
    }
}

// MARK: - Init from database

extension City {
    /// Creates a city model from a persisted record, preserving its local state.
    /// - Parameter model: The persisted city record.
    init(_ model: CityDataModel) {
        self.id = model.id
        self.name = model.name
        self.coordinates = .init(latitude: model.latitude, longitude: model.longitude)
        self.country = model.country
        self.administrativeArea = model.administrativeArea
        self.isFavorite = model.isFavorite
        self.lastSearchedAt = model.lastSearchedAt
    }
}

// MARK: - Hashable

extension City {
    /// Compares cities by the stable identifier returned by the geocoding service.
    static func == (lhs: City, rhs: City) -> Bool {
        lhs.id == rhs.id
    }

    /// Hashes the city using its stable geocoding identifier.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
