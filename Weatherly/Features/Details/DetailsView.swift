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
                ScrollView {
                    VStack {
                        currentWeather(weather)
                        hourlyWeather(weather)
                        dailyWeather(weather)
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            case .error:
                unavailable(
                    image: "exclamationmark.triangle",
                    title: "Common.error.title",
                    description: "Common.error.description"
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
        .toolbar {
            if case let .modal(onAdd) = viewModel.source {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        router.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                if !viewModel.city.isFavorite {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            guard viewModel.addToFavorite() else {
                                viewModel.addToFavoriteAlert = true
                                return
                            }
                            onAdd()
                            router.dismiss()
                        } label: {
                            Image(systemName: "plus")
                        }
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
}

// MARK: - Subviews

extension DetailsView {
    private func currentWeather(_ weather: Weather) -> some View {
        VStack(spacing: 12.0) {
            Text(viewModel.city.name)
                .lineLimit(1)
                .font(.largeTitle)
            
            HStack {
                Image(systemName: weather.current.condition.systemImage)
                    .font(.system(size: 40, weight: .regular))
                Text("\(Int(weather.current.temperature))°C")
                    .font(.system(size: 64, weight: .light))
            }
            
            Text(weather.current.condition.localizedDescription)
                .font(.title3)
            
            if let today = weather.daily.first,
               let minTemperature = today.minimumTemperature,
               let maxTemperature = today.maximumTemperature {
                HStack(spacing: 6.0) {
                    Text("Favorites.temperature.from")
                    Text("\(Int(minTemperature))°C")
                    Text("Favorites.temperature.to")
                    Text("\(Int(maxTemperature))°C")
                }
                .lineLimit(1)
                .font(.headline)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .liquidBackgroundIdNeeded()
    }
    
    private func hourlyWeather(_ weather: Weather) -> some View {
        VStack(alignment: .leading) {
            Text("Details.hourly.title")
                .font(.headline)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(weather.hourly, id: \.time) { hour in
                        VStack(spacing: 12) {
                            Text(hour.time.hourLabel)
                                .font(.subheadline)
                            
                            if let temperature = hour.temperature {
                                Text("\(Int(temperature))°")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            if let probability = hour.precipitationProbability {
                                HStack(spacing: 4.0) {
                                    Image(systemName: "drop.fill")
                                        .font(.caption)
                                    Text("\(Int(probability))%")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.cyan)
                            }
                        }
                        .frame(width: 66, height: 112)
                        .liquidBackgroundIdNeeded()
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidBackgroundIdNeeded()
    }
    
    private func dailyWeather(_ weather: Weather) -> some View {
        VStack(alignment: .leading, spacing: 12.0) {
            Text("Details.daily.title")
                .font(.headline)
            
            VStack(spacing: 12.0) {
                ForEach(weather.daily, id: \.time) { day in
                    HStack {
                        Text(day.time.dateLabel(timezone: weather.timezone).capitalized)
                            .lineLimit(1)
                            .frame(width: 64.0, alignment: .leading)
                        
                        Image(systemName: day.condition.systemImage)
                            .font(.title3)
                            .frame(width: 32.0)
                        
                        if let probability = day.maximumPrecipitationProbability {
                            HStack(spacing: 4.0) {
                                Image(systemName: "drop.fill")
                                    .font(.caption)
                                Text("\(Int(probability))%")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.cyan)
                        }
                        Spacer()
                        
                        if let minTemperature = day.minimumTemperature {
                            Text("\(Int(minTemperature))°")
                                .foregroundStyle(.secondary)
                                .frame(width: 32.0, alignment: .trailing)
                        }
                        if let maxTemperature = day.maximumTemperature {
                            Text("\(Int(maxTemperature))°")
                                .frame(width: 32.0, alignment: .trailing)
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidBackgroundIdNeeded()
    }
    
    private func unavailable(
        image: String,
        title: LocalizedStringResource,
        description: LocalizedStringResource
    ) -> some View {
        ContentUnavailableView {
            Label {
                Text(title)
            } icon: {
                Image(systemName: image)
                    .font(.headline)
            }
        } description: {
            Text(description)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.8),
                Color.blue.opacity(0.4),
                Color.indigo.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
