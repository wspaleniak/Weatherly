//
//  DetailsView.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 22/11/2026.
//

import FactoryKit
import SwiftUI

@MainActor
struct DetailsView: View {
    
    // MARK: - Properties
    
    @InjectedObservable(\.appRouter)
    private var router

    @Bindable
    var viewModel: DetailsViewModel

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.state {
            case .downloading:
                ProgressView {
                    Text("Details.loading")
                }
            case .downloaded(let weather):
                weatherContent(weather)
            case .error:
                ContentUnavailableView {
                    Label {
                        Text("Common.error.title")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                    }
                } description: {
                    Text("Common.error.description")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .toolbar {
            if isModal {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        router.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("Details.close"))
                }

                if didAddFavorite {
                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: "checkmark")
                    }
                } else if !viewModel.city.isFavorite {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            addToFavorite()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(Text("Favorites.add"))
                    }
                }
            }
        }
        .alert(
            Text("Common.error.title"),
            isPresented: $viewModel.addToFavoriteAlert
        ) {
            Button(role: .cancel) { } label: {
                Text("Details.close")
            }
        } message: {
            Text("Details.favorite.save.error")
        }
    }

    // MARK: - Actions

    private func addToFavorite() {
        guard viewModel.addToFavorite() else {
            viewModel.addToFavoriteAlert = true
            return
        }

        didAddFavorite = true

        guard case let .modal(onAdd) = viewModel.source else { return }
        onAdd()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            router.dismiss()
        }
    }

    // MARK: - Content

    private func weatherContent(_ weather: Weather) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                currentWeatherSection(weather)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        hourlyForecastSection(weather)
                            .frame(width: 320)
                        dailyForecastSection(weather)
                            .frame(width: 320)
                    }

                    VStack(spacing: 16) {
                        hourlyForecastSection(weather)
                        dailyForecastSection(weather)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private func currentWeatherSection(_ weather: Weather) -> some View {
        VStack(spacing: 10) {
            Text(viewModel.city.name)
                .font(.largeTitle.weight(.semibold))
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Image(systemName: weather.current.condition.systemImage)
                    .font(.system(size: 40, weight: .regular))

                Text("\(Int(weather.current.temperature.rounded()))°C")
                    .font(.system(size: 64, weight: .light, design: .rounded))
            }

            Text(weather.current.condition.localizedDescription)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))

            if let today = weather.daily.first,
               let minimum = today.minimumTemperature,
               let maximum = today.maximumTemperature {
                HStack(spacing: 4) {
                    Text("Details.temperature.from")
                    Text("\(Int(minimum.rounded()))°C")
                    Text("Details.temperature.to")
                    Text("\(Int(maximum.rounded()))°C")
                }
                .font(.headline)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(cardBackground)
    }

    private func hourlyForecastSection(_ weather: Weather) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details.hourly.title")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(weather.hourly, id: \.time) { hour in
                        VStack(spacing: 12) {
                            Text(hourLabel(hour.time))
                                .font(.subheadline.weight(.medium))

                            if let temperature = hour.temperature {
                                Text("\(Int(temperature.rounded()))°")
                                    .font(.title3.weight(.medium))
                            } else {
                                Text("—")
                                    .font(.title3.weight(.medium))
                            }

                            if let probability = hour.precipitationProbability {
                                Label("\(Int(probability.rounded()))%", systemImage: "drop.fill")
                                    .font(.caption)
                                    .foregroundStyle(.cyan)
                            } else {
                                Image(systemName: "thermometer.medium")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(width: 66, height: 112)
                        .background(cardBackground)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func dailyForecastSection(_ weather: Weather) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details.daily.title")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(weather.daily, id: \.time) { day in
                        VStack(spacing: 12) {
                            Text(dayLabel(day.time, timezone: weather.timezone))
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)

                            Image(systemName: day.condition.systemImage)
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)

                            HStack(spacing: 5) {
                                Text(day.minimumTemperature.map { "\(Int($0.rounded()))°" } ?? "—")
                                    .foregroundStyle(.white.opacity(0.7))
                                Text(day.maximumTemperature.map { "\(Int($0.rounded()))°" } ?? "—")
                            }
                            .font(.subheadline.weight(.medium))

                            if let probability = day.maximumPrecipitationProbability {
                                Label("\(Int(probability.rounded()))%", systemImage: "drop.fill")
                                    .font(.caption)
                                    .foregroundStyle(.cyan)
                            } else {
                                Color.clear.frame(height: 14)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(width: 78, height: 112)
                        .background(cardBackground)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    // MARK: - Formatting and styling

    private func hourLabel(_ timestamp: String) -> String {
        guard let separator = timestamp.firstIndex(of: "T") else {
            return timestamp
        }
        return String(timestamp[timestamp.index(after: separator)...].prefix(5))
    }

    private func dayLabel(_ timestamp: String, timezone: TimeZone?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.timeZone = timezone ?? .current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: timestamp) else {
            return timestamp
        }
        if dateFormatter.string(from: .now) == timestamp {
            return String(localized: "Details.today")
        }

        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color.blue.opacity(0.72), Color.indigo.opacity(0.82)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
