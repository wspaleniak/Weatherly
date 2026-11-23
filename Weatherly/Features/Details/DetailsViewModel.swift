//
//  DetailsViewModel.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 22/11/2026.
//

import FactoryKit
import Foundation
import SwiftData

@MainActor
@Observable
final class DetailsViewModel {
    
    // MARK: - Source
    
    enum Source: Sendable {
        case push
        case modal(onAdd: @MainActor () -> Void)
    }

    // MARK: - State

    enum State: Hashable, Sendable {
        case downloading
        case downloaded(Weather)
        case error
    }

    // MARK: - Properties

    let city: City
    let source: Source
    var state: State = .downloading
    var addToFavoriteAlert: Bool = false
    
    @ObservationIgnored private var weatherTask: Task<Void, Never>?

    private let networkService: any Network.Providing
    private let cityDataService: SwiftDataService<CityDataModel>?

    // MARK: - Init

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
    
    deinit {
        weatherTask?.cancel()
    }

    // MARK: - Methods

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
