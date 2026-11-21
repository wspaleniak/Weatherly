//
//  AppRouter.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 21/11/2026.
//

import Foundation

/// Stores navigation state for the app's main stack and presented screen.
///
/// The main stack starts empty and represents the app's root screen. A presented
/// screen is managed separately, so dismissing it leaves the main stack unchanged.
@MainActor
@Observable
final class AppRouter {
    
    // MARK: - Screen
    
    /// Identifies a screen that the router can push or present.
    struct Screen: Identifiable, Hashable, Sendable {
        /// The identifier used by the app to resolve the destination.
        let id: String
    }
    
    // MARK: - Properties
    
    /// The screens pushed above the app's root screen.
    private(set) var stack: [Screen] = []

    /// The screen currently presented modally, if any.
    private(set) var presented: Screen?
    
    // MARK: - Methods
    
    /// Replaces the main navigation stack with the supplied path.
    /// - Parameter stack: The new stack of screens.
    func setStack(_ stack: [Screen]) {
        self.stack = stack
    }
    
    /// Pushes a screen onto the main navigation stack.
    /// - Parameter screen: The screen to push.
    func push(_ screen: Screen) {
        stack.append(screen)
    }
    
    /// Removes the top screen from the main stack when the stack isn't empty.
    func pop() {
        guard !stack.isEmpty else { return }
        stack.removeLast()
    }
    
    /// Returns to the root screen and dismisses any presented screen.
    func popToRoot() {
        stack = []
        presented = nil
    }
    
    /// Presents a screen modally without changing the main navigation stack.
    /// - Parameter screen: The screen to present.
    func present(_ screen: Screen) {
        presented = screen
    }
    
    /// Dismisses the currently presented screen, if any.
    func dismiss() {
        presented = nil
    }
}
