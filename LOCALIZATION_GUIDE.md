# ConstruApp Localization Guide

## Overview
ConstruApp now supports internationalization with English and Spanish languages. Users can switch between languages dynamically through the Settings view.

## Implementation

### Files Added
- `ConstruApp/en.lproj/Localizable.strings` - English translations
- `ConstruApp/es.lproj/Localizable.strings` - Spanish translations  
- `ConstruApp/Utilities/LocalizationManager.swift` - Manages language switching
- `ConstruApp/Views/SettingsView.swift` - Configuration interface

### How It Works

#### LocalizationManager
The `LocalizationManager` class handles:
- Language preference storage
- Dynamic bundle switching  
- Runtime language changes
- String localization helpers

#### Usage in Code
```swift
// Using the extension
"nav.projects".localized

// With format arguments
"log.view_all_entries".localized(args: count)

// Direct manager access
LocalizationManager.shared.localizedString(for: "key")
```

### Language Support

#### Current Languages
- **English** (`en`) - Default
- **Spanish** (`es`) - Full translation
- **System** - Follows device language

#### Adding New Languages
1. Create new `[lang].lproj/Localizable.strings` file
2. Add language to `LocalizationManager.SupportedLanguage` enum
3. Update bundle loading logic
4. Add translations for all keys

### User Interface

#### Accessing Settings
1. Tap settings gear icon in Projects list
2. Select preferred language
3. App updates immediately

#### Language Options
- **System**: Follow device language settings
- **English**: Force English regardless of device
- **Spanish**: Force Spanish regardless of device

### String Categories

#### Keys Organization
- `general.*` - Common actions (Cancel, Create, Done)
- `nav.*` - Navigation titles
- `project.*` - Project management
- `category.*` - Log categories and descriptions
- `filter.*` - Timeline and category filters
- `log.*` - Log entries and activity
- `blueprint.*` - Blueprint management
- `settings.*` - Configuration options
- `error.*` - Error messages
- `a11y.*` - Accessibility labels

### Technical Notes

#### Data Persistence
- Language preference saved to UserDefaults
- Survives app restarts
- No data migration required

#### Bundle Management
- Dynamic bundle switching for runtime changes
- Fallback to main bundle if language pack missing
- Thread-safe implementation

#### SwiftUI Integration  
- Uses `@ObservableObject` for reactive updates
- Environment object injection at app level
- Automatic UI refresh on language change

### Testing
Build and run on iOS Simulator to test:
1. Change device language to Spanish
2. Launch app with "System" setting
3. Switch to specific languages in Settings
4. Verify UI updates immediately
5. Restart app to confirm persistence

### Extending Translations

#### Adding New Strings
1. Add key to both `en.lproj/Localizable.strings` and `es.lproj/Localizable.strings`
2. Use descriptive key names with dot notation
3. Follow existing categories and naming conventions
4. Update views to use `.localized` extension

#### Translation Guidelines
- Keep Spanish translations culturally appropriate
- Maintain consistent terminology 
- Consider text length differences for UI layout
- Test on different screen sizes