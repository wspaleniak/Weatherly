//
//  SearchRowView.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 23/11/2026.
//

import SwiftUI

/// Displays one city search result and marks it when it is already a favorite.
struct SearchRowView: View {
    
    // MARK: - Properties
    
    /// The city represented by this search result.
    let city: City
    /// Runs when the user selects the result.
    let onTap: @MainActor () -> Void
    
    // MARK: - Computed properties
    
    /// Combines the city and country names when a country is available.
    private var title: String {
        if let country = city.country {
            "\(city.name), \(country)"
        } else {
            city.name
        }
    }
    
    // MARK: - Body
    
    /// Builds a selectable search result with an optional favorite marker.
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                Text(title)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if city.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.subheadline)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparatorTint(.secondary)
    }
}
