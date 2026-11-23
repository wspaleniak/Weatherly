//
//  View+LiquidBackground.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 23/11/2026.
//

import SwiftUI

extension View {
    /// Applies a Liquid Glass background when available and a material fallback otherwise.
    ///
    /// - Parameter interactive: Whether the glass responds to touch and pointer interactions.
    @ViewBuilder
    func liquidBackgroundIdNeeded(interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(
                .regular.interactive(interactive),
                in: RoundedRectangle(cornerRadius: 24.0, style: .continuous)
            )
        } else {
            background {
                RoundedRectangle(cornerRadius: 24.0, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}
