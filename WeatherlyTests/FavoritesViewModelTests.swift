import Foundation
import SwiftData
import Testing
@testable import Weatherly

@Suite(.serialized)
@MainActor
struct FavoritesViewModelTests {
    @Test func `when search input contains unsupported characters it keeps letters spaces and hyphens`() {
        let viewModel = FavoritesViewModel(
            networkService: NetworkServiceStub(),
            cityDataService: nil
        )

        viewModel.updateSearchText("Łódź123! -Żółć")

        #expect(viewModel.searchText == "Łódź -Żółć")
    }

    @Test func `when search returns a saved city it marks that result as favorite`() async throws {
        let service = try makeInMemoryCityDataService()
        let savedFavorite = makeTestCity(isFavorite: true)
        service.insert(.init(city: savedFavorite, lastSearchedAt: .now))

        let searchResult = makeTestCity(isFavorite: false)
        let viewModel = FavoritesViewModel(
            networkService: NetworkServiceStub(searchResult: .success([searchResult])),
            cityDataService: service
        )

        viewModel.updateSearchText("Warszawa")
        await waitForSearchCompletion(viewModel)

        guard case let .downloaded(cities) = viewModel.searchState else {
            Issue.record("Expected search results to be downloaded.")
            return
        }
        #expect(cities.count == 1)
        #expect(cities[0].isFavorite)
    }

    @Test func `when recording an existing city it preserves its favorite state`() throws {
        let service = try makeInMemoryCityDataService()
        let favorite = makeTestCity(isFavorite: true, lastSearchedAt: Date(timeIntervalSince1970: 1))
        service.insert(.init(city: favorite, lastSearchedAt: Date(timeIntervalSince1970: 1)))
        let viewModel = FavoritesViewModel(
            networkService: NetworkServiceStub(),
            cityDataService: service
        )

        viewModel.record(city: makeTestCity(isFavorite: false))

        let savedCity = try #require(service.fetch().first)
        #expect(savedCity.isFavorite)
        #expect(savedCity.lastSearchedAt > Date(timeIntervalSince1970: 1))
    }

    @Test func `when removing a favorite it remains in the database as a recent search`() throws {
        let service = try makeInMemoryCityDataService()
        let favorite = makeTestCity(isFavorite: true)
        service.insert(.init(city: favorite, lastSearchedAt: .now))
        let viewModel = FavoritesViewModel(
            networkService: NetworkServiceStub(),
            cityDataService: service
        )

        viewModel.remove(city: favorite)

        let savedCity = try #require(service.fetch().first)
        #expect(!savedCity.isFavorite)
        #expect(viewModel.state == .downloaded([]))
    }

    @Test func `when weather for a favorite fails it keeps the city without forecast data`() async throws {
        let service = try makeInMemoryCityDataService()
        let favorite = makeTestCity(isFavorite: true)
        service.insert(.init(city: favorite, lastSearchedAt: .now))
        let viewModel = FavoritesViewModel(
            networkService: NetworkServiceStub(
                weatherResult: .failure(.downloading(message: "Offline"))
            ),
            cityDataService: service
        )

        await waitForFavoritesCompletion(viewModel)

        guard case let .downloaded(cities) = viewModel.state else {
            Issue.record("Expected the favorites list to finish loading.")
            return
        }
        #expect(cities.count == 1)
        #expect(cities[0].city.id == favorite.id)
        #expect(cities[0].weather == nil)
    }

    /// Waits for the debounced search task to publish either results or an error.
    private func waitForSearchCompletion(_ viewModel: FavoritesViewModel) async {
        for _ in 0..<100 {
            if case .downloaded = viewModel.searchState { return }
            if case .error = viewModel.searchState { return }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    /// Waits for the favorites task to publish its completed list.
    private func waitForFavoritesCompletion(_ viewModel: FavoritesViewModel) async {
        for _ in 0..<100 {
            if case .downloaded = viewModel.state { return }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }
}
