//
//  WeatherlyApp.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 16/11/2026.
//

import SwiftUI

@MainActor
@main
struct WeatherlyApp: App {
    private let favoritesViewModel = FavoritesViewModel()
    
    // MARK: - Init
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            FavoritesView(viewModel: favoritesViewModel)
        }
    }
}
