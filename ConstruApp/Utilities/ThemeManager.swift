//
//  ThemeManager.swift
//  ConstruApp
//
//  Created by Claude on 8/6/25.
//

import Foundation
import SwiftUI

/// Manages app theme and dynamic appearance switching
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    /// Supported app themes
    enum AppTheme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light:
                return "theme.light".localized
            case .dark:
                return "theme.dark".localized
            case .system:
                return "theme.system".localized
            }
        }
        
        var iconName: String {
            switch self {
            case .light:
                return "sun.max"
            case .dark:
                return "moon"
            case .system:
                return "gear"
            }
        }
    }
    
    /// Color semantic types for adaptive theming
    enum ColorType {
        case primary, secondary, tertiary
        case background, secondaryBackground, cardBackground, surfaceBackground
        case primaryText, secondaryText, tertiaryText, placeholderText
        case interactive, interactiveLight, hover, pressed, disabled
        case success, warning, error, info
        case shadow, cardShadow, floatingShadow
        case buttonText // Text on colored buttons
        
        // Log category colors
        case electrical, plumbing, structural, hvac, insulation
        case flooring, roofing, windows, doors, finishes, safety, general
    }
    
    @Published private(set) var currentTheme: AppTheme
    @Published private(set) var isDarkMode: Bool = false
    
    private init() {
        // Load saved theme preference or default to system
        let savedTheme = UserDefaults.standard.string(forKey: "app_theme") ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
        
        updateCurrentAppearance()
    }
    
    /// Sets the app theme and updates appearance
    /// - Parameter theme: The theme to set
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        
        // Save preference
        UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
        
        updateCurrentAppearance()
    }
    
    /// Updates the current appearance based on theme setting
    private func updateCurrentAppearance() {
        switch currentTheme {
        case .system:
            isDarkMode = isSystemDarkMode
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        }
    }
    
    /// Returns adaptive color based on current theme
    /// - Parameter type: The semantic color type
    /// - Returns: Color adapted to current theme
    func adaptiveColor(_ type: ColorType) -> Color {
        if isDarkMode {
            return darkColor(for: type)
        } else {
            return lightColor(for: type)
        }
    }
    
    /// Light theme color palette
    private func lightColor(for type: ColorType) -> Color {
        switch type {
        // Primary colors
        case .primary:
            return Color(red: 0.0, green: 0.3, blue: 0.6) // blueprintBlue
        case .secondary:
            return Color(red: 0.15, green: 0.15, blue: 0.17) // architectGray
        case .tertiary:
            return Color(red: 0.35, green: 0.37, blue: 0.4) // slate
            
        // Backgrounds
        case .background:
            return Color(.systemBackground)
        case .secondaryBackground:
            return Color(red: 0.95, green: 0.95, blue: 0.97) // lightArchitectGray
        case .cardBackground:
            return Color(.systemBackground)
        case .surfaceBackground:
            return Color(red: 0.98, green: 0.98, blue: 0.99) // paper
            
        // Text colors
        case .primaryText:
            return Color(red: 0.1, green: 0.1, blue: 0.12) // ink
        case .secondaryText:
            return Color(red: 0.2, green: 0.2, blue: 0.22) // charcoal
        case .tertiaryText:
            return Color(red: 0.35, green: 0.37, blue: 0.4) // slate
        case .placeholderText:
            return Color(red: 0.85, green: 0.85, blue: 0.87) // concrete
            
        // Interactive colors
        case .interactive:
            return Color(red: 0.0, green: 0.3, blue: 0.6)
        case .interactiveLight:
            return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .hover:
            return Color(red: 0.0, green: 0.3, blue: 0.6).opacity(0.8)
        case .pressed:
            return Color(red: 0.0, green: 0.3, blue: 0.6).opacity(0.9)
        case .disabled:
            return Color(red: 0.85, green: 0.85, blue: 0.87)
            
        // Status colors
        case .success:
            return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .warning:
            return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .error:
            return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .info:
            return Color(red: 0.0, green: 0.3, blue: 0.6)
            
        // Shadows
        case .shadow:
            return Color.black.opacity(0.06)
        case .cardShadow:
            return Color.black.opacity(0.08)
        case .floatingShadow:
            return Color.black.opacity(0.12)
            
        // Button text
        case .buttonText:
            return Color.white
            
        // Category colors (unchanged for brand consistency)
        case .electrical:
            return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .plumbing:
            return Color(red: 0.0, green: 0.5, blue: 0.8)
        case .structural:
            return Color(red: 0.4, green: 0.4, blue: 0.42)
        case .hvac:
            return Color(red: 0.6, green: 0.3, blue: 0.8)
        case .insulation:
            return Color(red: 0.9, green: 0.5, blue: 0.1)
        case .flooring:
            return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .roofing:
            return Color(red: 0.7, green: 0.2, blue: 0.2)
        case .windows:
            return Color(red: 0.0, green: 0.7, blue: 0.8)
        case .doors:
            return Color(red: 0.0, green: 0.6, blue: 0.4)
        case .finishes:
            return Color(red: 0.8, green: 0.4, blue: 0.6)
        case .safety:
            return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .general:
            return Color(red: 0.5, green: 0.5, blue: 0.52)
        }
    }
    
    /// Dark theme color palette
    private func darkColor(for type: ColorType) -> Color {
        switch type {
        // Primary colors - Keep brand identity but adapt for dark
        case .primary:
            return Color(red: 0.4, green: 0.6, blue: 0.9) // Brighter blueprint blue
        case .secondary:
            return Color(red: 0.7, green: 0.7, blue: 0.75) // Light gray
        case .tertiary:
            return Color(red: 0.6, green: 0.6, blue: 0.65) // Medium gray
            
        // Backgrounds - Professional dark theme
        case .background:
            return Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
        case .secondaryBackground:
            return Color(red: 0.17, green: 0.17, blue: 0.18) // #2C2C2E
        case .cardBackground:
            return Color(red: 0.17, green: 0.17, blue: 0.18) // #2C2C2E
        case .surfaceBackground:
            return Color(red: 0.20, green: 0.20, blue: 0.21) // #333336
            
        // Text colors - High contrast for readability
        case .primaryText:
            return Color(red: 1.0, green: 1.0, blue: 1.0) // White
        case .secondaryText:
            return Color(red: 0.68, green: 0.68, blue: 0.70) // #AEAEB2
        case .tertiaryText:
            return Color(red: 0.55, green: 0.55, blue: 0.58) // #8E8E93
        case .placeholderText:
            return Color(red: 0.42, green: 0.42, blue: 0.45) // #6C6C70
            
        // Interactive colors - Maintain blueprint blue brand
        case .interactive:
            return Color(red: 0.4, green: 0.6, blue: 0.9)
        case .interactiveLight:
            return Color(red: 0.5, green: 0.7, blue: 0.95)
        case .hover:
            return Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.8)
        case .pressed:
            return Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.9)
        case .disabled:
            return Color(red: 0.42, green: 0.42, blue: 0.45)
            
        // Status colors - Adapted for dark backgrounds
        case .success:
            return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .warning:
            return Color(red: 1.0, green: 0.7, blue: 0.1)
        case .error:
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .info:
            return Color(red: 0.4, green: 0.6, blue: 0.9)
            
        // Shadows - Deeper shadows for dark mode
        case .shadow:
            return Color.black.opacity(0.25)
        case .cardShadow:
            return Color.black.opacity(0.3)
        case .floatingShadow:
            return Color.black.opacity(0.4)
            
        // Button text - White on both themes for primary buttons
        case .buttonText:
            return Color.white
            
        // Category colors - Slightly brighter for dark backgrounds
        case .electrical:
            return Color(red: 1.0, green: 0.85, blue: 0.1) // Brighter amber
        case .plumbing:
            return Color(red: 0.2, green: 0.6, blue: 0.9) // Brighter ocean blue
        case .structural:
            return Color(red: 0.6, green: 0.6, blue: 0.62) // Lighter steel gray
        case .hvac:
            return Color(red: 0.7, green: 0.4, blue: 0.9) // Brighter purple
        case .insulation:
            return Color(red: 1.0, green: 0.6, blue: 0.2) // Brighter orange
        case .flooring:
            return Color(red: 0.7, green: 0.5, blue: 0.3) // Lighter wood brown
        case .roofing:
            return Color(red: 0.8, green: 0.3, blue: 0.3) // Brighter clay red
        case .windows:
            return Color(red: 0.1, green: 0.8, blue: 0.9) // Brighter sky blue
        case .doors:
            return Color(red: 0.1, green: 0.7, blue: 0.5) // Brighter forest green
        case .finishes:
            return Color(red: 0.9, green: 0.5, blue: 0.7) // Brighter rose
        case .safety:
            return Color(red: 1.0, green: 0.3, blue: 0.3) // Brighter alert red
        case .general:
            return Color(red: 0.6, green: 0.6, blue: 0.62) // Lighter neutral gray
        }
    }
    
    /// Check if system is in dark mode
    private var isSystemDarkMode: Bool {
        // Cache the result to avoid expensive UI traversal on every call
        UITraitCollection.current.userInterfaceStyle == .dark
    }
    
    /// Handle system appearance changes
    func handleSystemAppearanceChange() {
        if currentTheme == .system {
            updateCurrentAppearance()
        }
    }
}

// MARK: - SwiftUI Integration
extension View {
    /// Apply theme-aware styling
    func themed() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
    
    /// Watch for theme changes
    func watchThemeChanges() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
}