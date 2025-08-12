//
//  AppearanceHandler.swift
//  ConstruApp
//
//  Created by Claude on 8/6/25.
//

import SwiftUI

/// Handles system appearance changes and integrates with ThemeManager
struct AppearanceHandler: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .onChange(of: colorScheme) { _, newColorScheme in
                // Handle system appearance changes when using system theme
                if themeManager.currentTheme == .system {
                    themeManager.handleSystemAppearanceChange()
                }
            }
    }
}

extension View {
    /// Adds system appearance change handling to the view
    func handleAppearanceChanges() -> some View {
        modifier(AppearanceHandler())
    }
}