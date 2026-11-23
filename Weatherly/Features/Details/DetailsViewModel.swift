//
//  DetailsViewModel.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 22/11/2026.
//

import FactoryKit
import Foundation
import SwiftData

/// Loads the forecast for one city and adds that city to favorites when requested.
@MainActor
@Observable
final class DetailsViewModel {
    
    // MARK: - Source
    
    /// Describes how the details screen was opened and how a modal add action is handled.
    enum Source: Sendable {
        /// The screen was pushed onto the main navigation stack.
        case push
        /// The screen was presented modally; the closure runs after a successful favorite save.
        case modal(onAdd: @MainActor () -> Void)
    }

    // MARK: - State

    /// The loading result for this city's weather forecast.
    enum State: Hashable, Sendable {
        /// The forecast request is in progress.
        case downloading
        /// The forecast was loaded successfully.
        case downloaded(Weather)
        /// The forecast request failed.
        case error
    }

    // MARK: - Properties

    /// The city whose forecast is displayed.
    let city: City
    /// The navigation context used to configure the screen's toolbar.
    let source: Source
    /// The current forecast loading state.
    var state: State = .downloading
    /// Controls presentation of the favorite-save failure alert.
    var addToFavoriteAlert: Bool = false
    
    /// The active forecast request, canceled when replaced or released.
    @ObservationIgnored private var weatherTask: Task<Void, Never>?

    /// Retrieves forecasts from Open-Meteo.
    private let networkService: any Network.Providing
    /// Persists favorite state when SwiftData is available.
    private let cityDataService: SwiftDataService<CityDataModel>?

    // MARK: - Init

    /// Creates the view model and immediately starts loading the city's forecast.
    ///
    /// - Parameters:
    ///   - city: The city whose weather should be loaded.
    ///   - source: The navigation context for the details screen.
    ///   - networkService: The weather service. Defaults to the FactoryKit dependency.
    ///   - cityDataService: The persistence service, or `nil` if unavailable.
    init(
        city: City,
        source: Source,
        networkService: any Network.Providing = dependency(\.networkService),
        cityDataService: SwiftDataService<CityDataModel>? = dependency(\.cityDataService)
    ) {
        self.city = city
        self.source = source
        self.networkService = networkService
        self.cityDataService = cityDataService
        
        loadWeather()
    }
    
    /// Cancels the active forecast request when the view model is released.
    deinit {
        weatherTask?.cancel()
    }

    // MARK: - Methods

    /// Requests the latest forecast for the view model's city.
    ///
    /// Cancels any previous request, publishes `.downloading`, then publishes either
    /// `.downloaded` or `.error` if the request completes without being canceled.
    func loadWeather() {
        state = .downloading
        weatherTask?.cancel()
        weatherTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let weather = try await networkService.weather(
                    for: city.coordinates
                )
                guard !Task.isCancelled else { return }
                state = .downloaded(weather)
            } catch {
                guard !Task.isCancelled else { return }
                state = .error
            }
        }
    }
    
    /// Marks the city as a favorite in SwiftData.
    ///
    /// Updates an existing record or inserts a new record when the city has not yet
    /// been persisted. Returns `false` if the data service or persistence operation fails.
    /// - Returns: Whether the favorite state was saved successfully.
    func addToFavorite() -> Bool {
        guard let service = cityDataService else {
            return false
        }
        do {
            let cityID = city.id
            let descriptor = FetchDescriptor<CityDataModel>(
                predicate: #Predicate { $0.id == cityID }
            )
            if let savedCity = try service.fetch(descriptor).first {
                savedCity.isFavorite = true
            } else {
                var favoriteCity = city
                favoriteCity.isFavorite = true
                let searchedAt = favoriteCity.lastSearchedAt ?? Date()
                service.insert(.init(city: favoriteCity, lastSearchedAt: searchedAt))
            }
            return true
        } catch {
            return false
        }
    }
}
