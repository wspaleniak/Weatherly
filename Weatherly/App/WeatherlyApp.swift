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
    
    // MARK: - Properties
    
    /// The view model shared by the root favorites screen.
    private let favoritesViewModel = FavoritesViewModel()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            FavoritesView(viewModel: favoritesViewModel)
                .onAppear {
                    UISearchTextField.appearance().tintColor = .label
                }
        }
    }
}
