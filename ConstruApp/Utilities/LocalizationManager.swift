//
//  LocalizationManager.swift
//  ConstruApp
//
//  Created by Claude on 8/6/25.
//

import Foundation
import SwiftUI

/// Manages app localization and dynamic language switching
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    /// Supported languages in the app
    enum SupportedLanguage: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .english:
                return NSLocalizedString("language.english", comment: "English language name")
            case .spanish:
                return NSLocalizedString("language.spanish", comment: "Spanish language name")
            case .system:
                return NSLocalizedString("language.system", comment: "System language option")
            }
        }
        
        var nativeDisplayName: String {
            switch self {
            case .english:
                return "English"
            case .spanish:
                return "Español"
            case .system:
                return "System"
            }
        }
    }
    
    @Published private(set) var currentLanguage: SupportedLanguage
    private var bundle: Bundle
    
    private init() {
        // Load saved language preference or default to system
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? SupportedLanguage.system.rawValue
        self.currentLanguage = SupportedLanguage(rawValue: savedLanguage) ?? .system
        self.bundle = Bundle.main
        
        setLanguage(currentLanguage)
    }
    
    /// Sets the app language and updates the bundle
    /// - Parameter language: The language to set
    func setLanguage(_ language: SupportedLanguage) {
        currentLanguage = language
        
        // Save preference
        UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        
        // Update bundle based on language
        let languageCode: String
        switch language {
        case .system:
            languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            languageCode = "en"
        case .spanish:
            languageCode = "es"
        }
        
        // Load the appropriate bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            // Fallback to main bundle if specific language bundle not found
            self.bundle = Bundle.main
        }
    }
    
    /// Returns localized string for the given key
    /// - Parameters:
    ///   - key: The localization key
    ///   - comment: Optional comment for translators
    /// - Returns: Localized string
    func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
    
    /// Returns localized string with format arguments
    /// - Parameters:
    ///   - key: The localization key
    ///   - args: Format arguments
    /// - Returns: Formatted localized string
    func localizedString(for key: String, args: CVarArg...) -> String {
        let format = localizedString(for: key)
        return String(format: format, arguments: args)
    }
    
    /// Convenience method to get current language code
    var currentLanguageCode: String {
        switch currentLanguage {
        case .system:
            return Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            return "en"
        case .spanish:
            return "es"
        }
    }
}

// MARK: - String Extension for Easy Access
extension String {
    /// Returns localized version of the string
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    /// Returns localized string with format arguments
    /// - Parameter args: Format arguments
    /// - Returns: Formatted localized string
    func localized(args: CVarArg...) -> String {
        return LocalizationManager.shared.localizedString(for: self, args: args)
    }
}

// MARK: - SwiftUI View Extension
extension View {
    /// Triggers view updates when language changes
    func watchLanguageChanges() -> some View {
        self.environmentObject(LocalizationManager.shared)
    }
}