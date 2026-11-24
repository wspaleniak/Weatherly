//
//  FavoritesViewModel.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 22/11/2026.
//

import FactoryKit
import Foundation
import SwiftData

/// Loads favorite cities and coordinates city search and recent-search persistence.
///
/// The view model fetches persisted city records on startup and refresh, then uses
/// them to derive both the favorites list and the recent-search list.
@MainActor
@Observable
final class FavoritesViewModel {
    
    // MARK: - City with weather
    
    /// A persisted favorite city paired with its latest forecast, when available.
    struct CityWithWeather: Identifiable, Hashable, Sendable {
        /// The city's persisted identity and favorite state.
        let city: City
        /// The latest forecast, or `nil` when the weather request fails.
        let weather: Weather?

        /// Uses the city's stable geocoding identifier for list identity.
        var id: City.ID { city.id }
    }
    
    // MARK: - State
    
    /// The loading state for the favorites list.
    enum State: Hashable, Sendable {
        /// Favorite cities and their forecasts are being loaded.
        case downloading
        /// Favorite cities are available, with forecasts when requests succeeded.
        case downloaded([CityWithWeather])
    }
    
    // MARK: - Search state
    
    /// The content state for the city search list.
    enum SearchState: Hashable, Sendable {
        /// Displays cities stored from previous selections.
        case lastSearched([City])
        /// Displays results returned for the current query.
        case downloaded([City])
        /// A localized message describing a database or search failure.
        case error(String)
    }
    
    // MARK: - Properties
    
    /// The loading state and data shown by the favorites list.
    var state: State = .downloading
    /// The current content or error shown by city search.
    var searchState: SearchState = .lastSearched([])
    /// The sanitized text currently entered in the city search field.
    var searchText = ""
    /// The selected favorite city used by push navigation and the split-view detail column.
    var selectedFavoriteCity: City?
    /// The selected search result used to create the modal details screen.
    var selectedSearchCity: City?
    
    /// All persisted cities, including favorites and recent searches.
    @ObservationIgnored private var storedCities: [City] = []
    /// The active task loading weather for favorite cities.
    @ObservationIgnored private var favoritesTask: Task<Void, Never>?
    /// The active debounced city-search task.
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    
    /// Searches for cities and retrieves weather forecasts.
    private let networkService: any Network.Providing
    /// Persists city favorites and recent-search timestamps when the store is available.
    private let cityDataService: SwiftDataService<CityDataModel>?
    
    // MARK: - Init
    
    /// Creates the view model, loads persisted cities, and starts loading favorites.
    ///
    /// - Parameters:
    ///   - networkService: The service used for city searches and weather requests.
    ///   - cityDataService: The persistence service, or `nil` if the store is unavailable.
    ///   - state: The initial favorites state. Defaults to `.downloading`.
    init(
        networkService: any Network.Providing = dependency(\.networkService),
        cityDataService: SwiftDataService<CityDataModel>? = dependency(\.cityDataService),
        state: State = .downloading
    ) {
        self.networkService = networkService
        self.cityDataService = cityDataService
        self.state = state
        
        loadDatabase()
        loadFavorites(withSpinner: true)
    }
    
    /// Cancels active network tasks when the view model is released.
    deinit {
        favoritesTask?.cancel()
        searchTask?.cancel()
    }
    
    // MARK: - Methods
    
    /// Reloads persisted cities and refreshes weather for current favorites.
    func refresh() {
        loadDatabase()
        loadFavorites()
    }
}

// MARK: - Database

extension FavoritesViewModel {
    /// Fetches all persisted cities in most-recently-searched order.
    ///
    /// Updates the recent-search list unless a network result list is currently
    /// being displayed. A missing database or failed fetch becomes a search error.
    func loadDatabase() {
        guard let service = cityDataService else {
            searchState = .error(String(localized: "Search.error"))
            return
        }
        do {
            let descriptor = FetchDescriptor<CityDataModel>(
                sortBy: [SortDescriptor(\.lastSearchedAt, order: .reverse)]
            )
            let cities = try service.fetch(descriptor).map(City.init)
            storedCities = cities
            
            searchState = switch searchState {
            case .lastSearched, .error: .lastSearched(cities)
            case .downloaded(let cities): .downloaded(cities)
            }
        } catch {
            searchState = .error(String(localized: "Search.error"))
        }
    }
    
    /// Records a selected city as a recent search, inserting it if it is new.
    ///
    /// Existing favorite state is preserved when the city already exists in storage.
    /// - Parameter city: The city selected from search results.
    func record(city: City) {
        guard let service = cityDataService else {
            return
        }
        let searchedAt = Date()
        
        do {
            let cityID = city.id
            let descriptor = FetchDescriptor<CityDataModel>(
                predicate: #Predicate { $0.id == cityID }
            )
            if let savedCity = try service.fetch(descriptor).first {
                savedCity.lastSearchedAt = searchedAt
            } else {
                var updatedCity = city
                updatedCity.lastSearchedAt = searchedAt
                service.insert(.init(city: updatedCity, lastSearchedAt: searchedAt))
            }
            loadDatabase()
        } catch {
            return
        }
    }
    
    /// Removes a city from favorites while retaining it in recent searches.
    /// - Parameter city: The city to remove from the favorites list.
    func remove(city: City) {
        guard let service = cityDataService else {
            return
        }
        do {
            let cityID = city.id
            let descriptor = FetchDescriptor<CityDataModel>(
                predicate: #Predicate { $0.id == cityID }
            )
            guard let savedCity = try service.fetch(descriptor).first else {
                return
            }
            savedCity.isFavorite = false
            loadDatabase()
            loadFavorites()
        } catch {
            return
        }
    }
}

// MARK: - Favorites

extension FavoritesViewModel {
    /// Loads forecasts for persisted favorites and publishes the sorted list.
    ///
    /// Forecasts are requested concurrently. A failed weather request leaves the
    /// city in the list with a `nil` forecast. The spinner is shown only when
    /// `withSpinner` is `true`.
    /// - Parameter withSpinner: Whether to show the initial loading state.
    func loadFavorites(withSpinner: Bool = false) {
        let cities = storedCities
            .filter(\.isFavorite)
            .sorted { $0.name < $1.name }
        
        selectedFavoriteCity = cities.first
        
        guard !cities.isEmpty else {
            favoritesTask?.cancel()
            state = .downloaded([])
            return
        }
        if withSpinner {
            state = .downloading
        }
        favoritesTask?.cancel()
        favoritesTask = Task { @MainActor [weak self] in
            let citiesWithWeather = await withTaskGroup(
                of: CityWithWeather.self
            ) { [weak self] group in
                for city in cities {
                    group.addTask { [weak self] in
                        let weather = try? await self?.networkService.weather(
                            for: city.coordinates
                        )
                        return .init(city: city, weather: weather)
                    }
                }
                var results: [CityWithWeather] = []
                for await result in group {
                    results.append(result)
                }
                return results.sorted {
                    $0.city.name < $1.city.name
                }
            }
            guard !Task.isCancelled else { return }
            self?.state = .downloaded(citiesWithWeather)
        }
    }
}

// MARK: - Search

extension FavoritesViewModel {
    /// Sanitizes search input and starts or resets the current search.
    ///
    /// Keeps Unicode letters, spaces, and hyphens, removing digits and other
    /// characters before sending the query to the network service.
    /// - Parameter newText: The latest text entered in the search field.
    func updateSearchText(_ newText: String) {
        let normalizedText = newText.precomposedStringWithCanonicalMapping
        let validatedText = normalizedText.replacingOccurrences(
            of: #"[^\p{L} -]"#,
            with: "",
            options: .regularExpression
        )
        guard validatedText != searchText else { return }

        searchText = validatedText
        search(validatedText)
    }

    /// Debounces a query, fetches matching cities, and marks saved favorites.
    ///
    /// An empty query restores the persisted recent-search list. Starting a new
    /// query cancels the previous search task.
    /// - Parameter newQuery: The sanitized query to search for.
    private func search(_ newQuery: String) {
        let query = newQuery.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !query.isEmpty else {
            searchTask?.cancel()
            searchState = .lastSearched(storedCities)
            return
        }
        searchTask?.cancel()
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: .seconds(0.5))
                guard !Task.isCancelled else { return }
                
                let cities = try await networkService.search(query).map { result in
                    var city = result
                    let favoritesIDs = storedCities.filter { $0.isFavorite }
                    city.isFavorite = favoritesIDs.map(\.id).contains(city.id)
                    return city
                }
                guard !Task.isCancelled else { return }
                searchState = .downloaded(cities)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                searchState = .error(String(localized: "Search.error"))
            }
        }
    }
}
