//
//  City.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 20/11/2026.
//

import Foundation

/// A location returned by a city search.
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
}

// MARK: - Init

extension City {
    /// Creates a city model from a geocoding response.
    ///
    /// - Parameter model: The decoded city returned by the geocoding API.
    init(_ model: Network.Decoding.Search.City) {
        self.id = model.id
        self.name = model.name
        self.coordinates = .init(latitude: model.latitude, longitude: model.longitude)
        self.country = model.country
        self.administrativeArea = model.admin1
    }
}
