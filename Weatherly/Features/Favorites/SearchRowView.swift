//
//  SearchRowView.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 23/11/2026.
//

import SwiftUI

struct SearchRowView: View {
    
    // MARK: - Properties
    
    let city: City
    let onTap: @MainActor () -> Void
    
    // MARK: - Computed properties
    
    private var title: String {
        if let country = city.country {
            "\(city.name), \(country)"
        } else {
            city.name
        }
    }
    
    // MARK: - Body
    
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
    }
}
