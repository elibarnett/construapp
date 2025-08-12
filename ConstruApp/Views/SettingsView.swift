//
//  SettingsView.swift
//  ConstruApp
//
//  Created by Claude on 8/6/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                languageSection
            }
            .navigationTitle("nav.settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("general.done".localized) {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        Section {
            ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                HStack {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: theme.iconName)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(theme.displayName)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if themeManager.currentTheme == theme {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        themeManager.setTheme(theme)
                    }
                }
            }
        } header: {
            Text("settings.appearance".localized)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        } footer: {
            Text(currentThemeFooterText)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
    
    private var languageSection: some View {
        Section {
            ForEach(LocalizationManager.SupportedLanguage.allCases, id: \.self) { language in
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(language.nativeDisplayName)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        if language != .system {
                            Text(language.displayName)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if localizationManager.currentLanguage == language {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        localizationManager.setLanguage(language)
                    }
                }
            }
        } header: {
            Text("settings.app_language".localized)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        } footer: {
            Text(currentLanguageFooterText)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
    
    private var currentThemeFooterText: String {
        switch themeManager.currentTheme {
        case .system:
            return "System theme will follow your device settings. Currently using: \(currentThemeDisplayName)"
        case .light:
            return "App will always display in light mode"
        case .dark:
            return "App will always display in dark mode"
        }
    }
    
    private var currentThemeDisplayName: String {
        return themeManager.isDarkMode ? "Dark" : "Light"
    }
    
    private var currentLanguageFooterText: String {
        switch localizationManager.currentLanguage {
        case .system:
            return "System language will follow your device settings. Currently using: \(systemLanguageDisplayName)"
        case .english:
            return "App will display in English regardless of system language"
        case .spanish:
            return "App will display in Spanish regardless of system language"
        }
    }
    
    private var systemLanguageDisplayName: String {
        let currentLanguageCode = localizationManager.currentLanguageCode
        return Locale.current.localizedString(forLanguageCode: currentLanguageCode) ?? currentLanguageCode.uppercased()
    }
}

#Preview {
    SettingsView()
}