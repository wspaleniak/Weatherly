//
//  FavoritesViewModel.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 22/11/2026.
//

import FactoryKit
import Foundation
import SwiftData

@MainActor
@Observable
final class FavoritesViewModel {
    
    // MARK: - City with weather
    
    struct CityWithWeather: Identifiable, Hashable, Sendable {
        let city: City
        let weather: Weather?

        var id: City.ID { city.id }
    }
    
    // MARK: - State
    
    enum State {
        case downloading
        case downloaded([CityWithWeather])
    }
    
    // MARK: - Search state
    
    enum SearchState {
        case lastSearched([City])
        case downloaded([City])
        case error(String)
    }
    
    // MARK: - Properties
    
    var state: State = .downloading
    var searchState: SearchState = .lastSearched([])
    var searchText = ""

    @ObservationIgnored private var storedCities: [City] = []
    @ObservationIgnored private var favoritesTask: Task<Void, Never>?
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    
    private let networkService: any Network.Providing
    private let cityDataService: SwiftDataService<CityDataModel>?
    
    // MARK: - Init
    
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
    
    deinit {
        favoritesTask?.cancel()
        searchTask?.cancel()
    }
    
    // MARK: - Methods
    
    func refresh() {
        loadDatabase()
        loadFavorites()
    }
}

// MARK: - Database

extension FavoritesViewModel {
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
    
    func record(city: City) {
        guard let service = cityDataService else {
            return
        }
        let searchedAt = Date()
        var updatedCity = city
        updatedCity.lastSearchedAt = searchedAt
        
        do {
            let cityID = city.id
            let descriptor = FetchDescriptor<CityDataModel>(
                predicate: #Predicate { $0.id == cityID }
            )
            if let savedCity = try service.fetch(descriptor).first {
                savedCity.lastSearchedAt = searchedAt
            } else {
                service.insert(.init(city: updatedCity, lastSearchedAt: searchedAt))
            }
            loadDatabase()
        } catch {
            return
        }
    }
}

// MARK: - Favorites

extension FavoritesViewModel {
    func loadFavorites(withSpinner: Bool = false) {
        let cities = storedCities.filter(\.isFavorite)
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
