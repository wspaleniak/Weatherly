//
//  View+LiquidBackground.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 23/11/2026.
//

import SwiftUI

extension View {
    /// Applies an interactive Liquid Glass background when available and uses a material fallback otherwise.
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
