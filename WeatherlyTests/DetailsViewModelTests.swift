import Foundation
import SwiftData
import Testing
@testable import Weatherly

@Suite(.serialized)
@MainActor
struct DetailsViewModelTests {
    @Test func `when weather request succeeds it publishes the forecast`() async {
        let weather = makeTestWeather()
        let viewModel = DetailsViewModel(
            city: makeTestCity(),
            source: .push,
            networkService: NetworkServiceStub(weatherResult: .success(weather)),
            cityDataService: nil
        )

        await waitForWeatherCompletion(viewModel)

        #expect(viewModel.state == .downloaded(weather))
    }

    @Test func `when weather request fails it publishes an error state`() async {
        let viewModel = DetailsViewModel(
            city: makeTestCity(),
            source: .push,
            networkService: NetworkServiceStub(
                weatherResult: .failure(.downloading(message: "Offline"))
            ),
            cityDataService: nil
        )

        await waitForWeatherCompletion(viewModel)

        #expect(viewModel.state == .error)
    }

    @Test func `when adding a new city to favorites it inserts a favorite record`() throws {
        let service = try makeInMemoryCityDataService()
        let city = makeTestCity()
        let viewModel = DetailsViewModel(
            city: city,
            source: .push,
            networkService: NetworkServiceStub(),
            cityDataService: service
        )

        #expect(viewModel.addToFavorite())

        let savedCity = try #require(service.fetch().first)
        #expect(savedCity.id == city.id)
        #expect(savedCity.isFavorite)
        #expect(savedCity.lastSearchedAt != .distantPast)
    }

    @Test func `when adding an existing city it preserves its recent-search date`() throws {
        let service = try makeInMemoryCityDataService()
        let searchedAt = Date(timeIntervalSince1970: 1_000)
        let city = makeTestCity(lastSearchedAt: searchedAt)
        service.insert(.init(city: city, lastSearchedAt: searchedAt))
        let viewModel = DetailsViewModel(
            city: city,
            source: .push,
            networkService: NetworkServiceStub(),
            cityDataService: service
        )

        #expect(viewModel.addToFavorite())

        let savedCity = try #require(service.fetch().first)
        #expect(savedCity.isFavorite)
        #expect(savedCity.lastSearchedAt == searchedAt)
    }

    @Test func `when the database is unavailable adding a favorite fails`() {
        let viewModel = DetailsViewModel(
            city: makeTestCity(),
            source: .push,
            networkService: NetworkServiceStub(),
            cityDataService: nil
        )

        #expect(!viewModel.addToFavorite())
    }

    /// Waits for the forecast request to leave its initial loading state.
    private func waitForWeatherCompletion(_ viewModel: DetailsViewModel) async {
        for _ in 0..<100 {
            if viewModel.state != .downloading { return }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }
}
