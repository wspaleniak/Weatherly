//
//  FavoritesRowView.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 23/11/2026.
//

import SwiftUI

struct FavoritesRowView: View {

    // MARK: - Properties

    let city: FavoritesViewModel.CityWithWeather
    let onTap: @MainActor () -> Void
    let onRemove: @MainActor () -> Void

    // MARK: - Body

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 16.0) {
                cityAndTemperature
                conditionAndTemperature
            }
            .padding()
            .contentShape(.rect)
            .liquidBackgroundIdNeeded(interactive: true)
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Image(systemName: "trash")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var cityAndTemperature: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(city.city.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let country = city.city.country{
                    Text(country)
                        .font(.subheadline)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let weather = city.weather {
                Text("\(Int(weather.current.temperature))°C")
                    .font(.system(size: 48.0, weight: .light))
                    .frame(alignment: .trailing)
            }
        }
    }
    
    private var conditionAndTemperature: some View {
        HStack(alignment: .bottom) {
            if let weather = city.weather {
                HStack {
                    Image(systemName: weather.current.condition.systemImage)
                    Text(weather.current.condition.localizedDescription)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.subheadline)
                .fontWeight(.medium)
            }
            if let today = city.weather?.daily.first,
               let minTemperature = today.minimumTemperature,
               let maxTemperature = today.maximumTemperature {
                HStack(spacing: 6.0) {
                    Text("Favorites.temperature.from")
                    Text("\(Int(minTemperature))°C")
                    Text("Favorites.temperature.to")
                    Text("\(Int(maxTemperature))°C")
                }
                .lineLimit(1)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(alignment: .trailing)
            }
        }
    }
}
