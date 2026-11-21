//
//  WeatherlyApp.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 16/11/2026.
//

import FactoryKit
import SwiftUI

@main
struct WeatherlyApp: App {
    
    // MARK: - Init
    
    init() {
        _ = Container.shared.locationService()
        _ = Container.shared.cityDataService()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            Text("Hello, world!")
        }
    }
}
