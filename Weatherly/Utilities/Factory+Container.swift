//
//  Factory+Container.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 21/11/2026.
//

import FactoryKit
import SwiftData

/// Registers the app's shared dependencies for FactoryKit injection.
extension Container {
    
    // MARK: - Network
    
    /// Creates the Open-Meteo service used to search for cities and load forecasts.
    var networkService: Factory<any Network.Providing> {
        self {
            Network.Service()
        }
    }
    
    // MARK: - Location

    /// Provides one location service shared by the app's consumers.
    ///
    /// Caching keeps the service's `CLLocationManager` and its authorization state
    /// shared across all consumers.
    @MainActor
    var locationService: Factory<LocationService> {
        self {
            LocationService()
        }
        .cached
    }
    
    // MARK: - Database

    /// Provides SwiftData operations for persisted cities when the store is available.
    ///
    /// Returns `nil` if SwiftData cannot create the persistent store.
    @MainActor
    var cityDataService: Factory<SwiftDataService<CityDataModel>?> {
        self {
            guard let modelContainer = try? ModelContainer(
                for: CityDataModel.self
            ) else { return nil }
            return SwiftDataService(modelContainer: modelContainer)
        }
        .cached
    }
}
