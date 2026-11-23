//
//  DetailsView.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 22/11/2026.
//

import SwiftUI

struct DetailsView: View {
    
    // MARK: - Source
    
    enum Source: Hashable, Sendable {
        case push, modal
    }
    
    // MARK: - Properties
    
    let city: City
    let source: Source
    
    @State
    private var viewModel = DetailsViewModel()
    
    // MARK: - Body
    
    var body: some View {
        // ...
    }
}
