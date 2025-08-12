# ConstruApp

ConstruApp is a comprehensive construction documentation and project management iOS application designed for architects, designers, contractors, and construction professionals. The app enables users to document and track the complete evolution of construction projects, from initial blueprints to final completion.

## Core Functionality

- **Project Management**: Create, modify, and manage construction projects.
- **Blueprint Integration**: Upload and interact with PDF blueprints.
- **Interactive Documentation**: Add location-specific pins to blueprints to log details.
- **Multimedia Logging**: Attach photos, videos, and notes to each log entry.
- **Categorization**: Organize logs by type (e.g., electrical, plumbing, structural).
- **Timeline Tracking**: Maintain a chronological record of all activities.
- **Spatial Search**: Search for logs within specific areas of a blueprint.

## Key Features

- **High-Fidelity Blueprint Viewer**: A smooth, performant blueprint viewer built with UIKit for native zoom and pan capabilities.
- **Multi-Level Media Gallery**: View all media associated with a project, a single blueprint, or a specific area of a blueprint.
- **Advanced Localization**: Full support for English and Spanish, with a dynamic language switching system.
- **Adaptive Theme**: A complete light/dark mode implementation that adapts to system settings or user preference.

## Technology Stack

- **UI**: SwiftUI (with a UIKit component for the PDF viewer)
- **Data Persistence**: SwiftData
- **Target OS**: iOS 18.5+

## Getting Started

To build and run the project, use the following command in your terminal. It is recommended to build for an iOS Simulator to avoid issues with device provisioning.

### Build for Debug

```bash
xcodebuild -project ConstruApp.xcodeproj -scheme ConstruApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Run Tests

```bash
# Run all unit tests
xcodebuild test -project ConstruApp.xcodeproj -scheme ConstruApp -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -project ConstruApp.xcodeproj -scheme ConstruAppUITests -destination 'platform=iOS Simulator,name=iPhone 16'
```