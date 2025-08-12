# Agent Instructions for ConstruApp

This document provides technical guidance for AI agents working on the ConstruApp codebase.

## Build and Development Commands

### Building the Project
Always specify an iOS Simulator destination to avoid provisioning errors.

```bash
# Build for debug (recommended)
xcodebuild -project ConstruApp.xcodeproj -scheme ConstruApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16'

# Build for release
xcodebuild -project ConstruApp.xcodeproj -scheme ConstruApp -configuration Release -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Running Tests
```bash
# Run all unit tests
xcodebuild test -project ConstruApp.xcodeproj -scheme ConstruApp -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -project ConstruApp.xcodeproj -scheme ConstruAppUITests -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

### Core Structure
- **`ConstruAppApp.swift`**: App entry point, SwiftData setup.
- **`ContentView.swift`**: Displays `ProjectListView`.
- **`DesignSystem.swift`**: Centralized styling.

### Data Layer (SwiftData)
- **Models**: `Project.swift`, `Blueprint.swift`, `LogEntry.swift`
- **Relationship**: `Project` -> `Blueprint` -> `LogEntry`
- **Constraint**: Use `projectDescription` instead of `description` for property names.
- **Deletion**: Cascade deletion is configured.

### UI Architecture
- **Navigation**: `NavigationStack`
- **Blueprint Viewer**: A pure UIKit implementation (`UIKitPDFViewController`, `UIKitPDFViewWrapper`, `PinOverlayView`) is used for performance.

## Critical Implementation Notes

### Coordinate System (CRITICAL)
- **Storage**: Store coordinates as **normalized values (0.0 to 1.0)**.
- **Origin**: (0,0) is top-left, (1,1) is bottom-right.
- **Page Numbers**: Start from 1.
- **`GlobalCoordinateStore`**: Use this singleton to handle coordinate persistence, especially for the "first tap" issue.

### SwiftData Constraints
- **`description` is a reserved property name.** Use `projectDescription` instead.
- The model container schema must include `Project.self`, `Blueprint.self`, and `LogEntry.self`.

### Design System
- **Always use `DesignSystem.swift`** for colors, fonts, and spacing.
- **Do not hardcode styles.** Use view modifiers like `.cardStyle()`.

### Localization
- **Add new strings to both `en.lproj/Localizable.strings` and `es.lproj/Localizable.strings`.**
- Use dot notation for keys (e.g., `project.create_button`).
- Use the `.localized` extension for strings.

### Light/Dark Mode
- Use semantic, adaptive colors from `DesignSystem.Colors` (e.g., `primaryText`, `cardBackground`).
- **Do not use static colors** like `.black`, `.white`, or brand colors for text content.

## Common Pitfalls to Avoid
1.  **Coordinate System**: Do not store absolute pixel coordinates.
2.  **SwiftData**: Do not use `description` as a property name.
3.  **Styling**: Do not hardcode colors or fonts.
4.  **Localization**: Do not hardcode user-facing strings.
5.  **Pin Tracking**: Do not modify the scroll view delegates (`scrollViewDidScroll`, `scrollViewDidZoom`) in `UIKitPDFViewController`.
6.  **Theme**: Do not use brand colors for text; use semantic colors like `primaryText`.
