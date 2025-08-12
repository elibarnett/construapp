# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ConstruApp** is a comprehensive construction documentation and project management iOS application designed specifically for architects, designers, contractors, and construction professionals. The app enables users to document and track the complete evolution of construction projects, from initial blueprints to final completion.

### Target Audience
Primary users are **architects and designers** who value both functionality and aesthetic excellence. The app must reflect the sophisticated design sensibilities of its users through:
- Clean, minimalist interface design
- Professional typography and spacing
- Thoughtful use of color and visual hierarchy  
- Intuitive gestures and smooth animations
- High-quality visual presentation of blueprints and documentation

### Main Goal
The primary objective of ConstruApp is to provide a digital solution for documenting construction progress, infrastructure installations, and modifications throughout a building's construction or renovation process. Users can maintain detailed records of critical infrastructure elements such as:

- Electrical wiring and cable routing (old and new installations)
- Plumbing and piping systems (water, gas, drainage)
- Structural support elements and modifications  
- HVAC installations and ductwork
- Any other construction-related infrastructure

### Core Functionality
- **Project Management**: Create, modify, and delete construction projects
- **Blueprint Integration**: Upload, manage, and interact with PDF blueprints
- **Interactive Documentation**: Add location-specific pins to blueprints for detailed logging
- **Multi-media Logging**: Attach photos, videos, and text notes to specific blueprint locations
- **Categorized Documentation**: Organize logs by type (electrical, plumbing, structural, etc.)
- **Temporal Tracking**: Maintain chronological records with date controls for construction timeline documentation
- **Spatial Analysis**: Query and view all logs of specific types within defined areas of blueprints
- **Historical Reference**: Enable future reference for maintenance, renovations, or troubleshooting
- **Multi-language Support**: Full internationalization with English and Spanish support

This solution addresses the critical need for maintaining accurate, accessible records of "behind-the-walls" infrastructure that becomes invisible once construction is complete.

**Technical Foundation**: Built with SwiftUI and SwiftData, targeting iOS 18.5+.

## Build and Development Commands

### Building the Project
```bash
# Build the project (RECOMMENDED - avoids device provisioning errors)
xcodebuild -project ConstruApp.xcodeproj -scheme ConstruApp -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16'

# Build for release (simulator)
xcodebuild -project ConstruApp.xcodeproj -scheme ConstruApp -configuration Release -destination 'platform=iOS Simulator,name=iPhone 16'

# Alternative: Build without specific destination (may cause provisioning errors)
# xcodebuild -project ConstruApp.xcodeproj -scheme ConstruApp -configuration Debug
```

**IMPORTANT**: Always specify an iOS Simulator destination when building to avoid device provisioning profile errors. The available iPhone simulators are iPhone 16, iPhone 16 Plus, iPhone 16 Pro, iPhone 16 Pro Max, and iPhone 16e. Use iPhone 16 as the default simulator target.

### Running Tests
```bash
# Run unit tests
xcodebuild test -project ConstruApp.xcodeproj -scheme ConstruApp -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test target
xcodebuild test -project ConstruApp.xcodeproj -scheme ConstruAppTests -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild test -project ConstruApp.xcodeproj -scheme ConstruAppUITests -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Development Environment
- Xcode 16.4+
- Swift 5.0
- iOS 18.5+ deployment target
- Development Team: VQLSG2U97D

## Architecture

### Core Structure
- **ConstruAppApp.swift**: Main app entry point with SwiftData model container setup
- **ContentView.swift**: Entry point that displays ProjectListView
- **DesignSystem.swift**: Centralized design tokens and styling system

### Data Layer (SwiftData)
The app uses SwiftData for persistence with three core models:

- **Project.swift**: Main project entity with metadata and relationships
- **Blueprint.swift**: PDF blueprints with coordinate mapping and page info
- **LogEntry.swift**: Location-specific log entries with multimedia support

#### Model Relationships
```
Project (1) -> (many) Blueprint (1) -> (many) LogEntry
```

#### Key Technical Decisions
- **Property Naming**: Use `projectDescription` instead of `description` (SwiftData restriction)
- **Coordinate System**: Store normalized coordinates (0-1) for device-independent positioning
- **PDF Storage**: Store PDF as `Data` directly in SwiftData for offline access
- **Cascade Deletion**: Configured for proper cleanup when deleting projects/blueprints

### UI Architecture

#### Navigation Pattern
- **NavigationStack**: Used throughout for iOS 16+ navigation
- **Master-Detail Flow**: Projects -> Blueprints -> Log Entries
- **Sheet Presentation**: Used for creation/editing workflows

#### Blueprint Viewer System
**Current Architecture**: The blueprint viewer uses a pure UIKit approach wrapped in SwiftUI for optimal performance and reliability:

- **UIKitPDFViewController**: Pure UIKit PDF controller with native zoom/pan behavior
- **UIKitPDFViewWrapper**: SwiftUI wrapper using UIViewControllerRepresentable
- **PDFView**: Standard PDFKit view for PDF rendering with proper scroll view delegate implementation
- **PinOverlayView**: Custom UIView overlaid for pin rendering and interaction, constrained to PDFView
- **Coordinate Mapping**: Direct PDFKit coordinate conversion for accurate pin placement and tracking

#### Design System Implementation
- **Centralized Styling**: All colors, typography, and spacing defined in DesignSystem.swift
- **Extension-Based**: View modifiers like `.cardStyle()` for consistent styling
- **Category Colors**: Each LogCategory has associated color and SF Symbol icon

### Pin System Technical Architecture

#### Coordinate System
**CRITICAL**: Never change this coordinate system without migration:
- Store coordinates as normalized values (0.0 to 1.0)
- X: 0.0 = left edge, 1.0 = right edge
- Y: 0.0 = top edge, 1.0 = bottom edge
- Page numbers start from 1 (not 0)

#### Pin Rendering and Coordinate System
- **Custom Drawing**: Uses Core Graphics for optimal performance with real-time updates
- **Hit Testing**: 30pt tap targets for pins (24pt visual + 6pt padding)
- **Visual Design**: Category-colored circles with white SF Symbol icons
- **Pulse Animation**: 10-second pulse effect for newly created pins
- **Coordinate Conversion**: `convertLogEntryToViewCoordinates` uses direct PDFKit coordinate mapping
- **Pin Tracking**: Pins automatically move with PDF content during pan/zoom operations
- **Overlay Constraints**: Pin overlay is constrained to PDFView bounds for proper movement tracking

#### Gesture Handling and Coordinate System
- **Gesture Coordination**: UIKit-based gesture recognition with proper delegate patterns
- **Hit Priority**: Pin taps take precedence over new pin creation via hit testing
- **Thread Safety**: All UI updates happen on main thread
- **Coordinate Mapping**: Direct conversion from touch coordinates to normalized PDF coordinates (0-1)
- **Y-Axis Handling**: Proper Y coordinate flipping between UIKit (top-left origin) and PDF (bottom-left origin)
- **State Persistence**: GlobalCoordinateStore singleton ensures coordinates survive SwiftUI view reconstructions
- **Dual Storage**: Coordinates stored in both SwiftUI @State variables and global singleton for reliability

#### Zoom System Implementation
**Current Implementation**: Native UIKit scroll view zoom with proper center-preserving behavior:

- **Native Zoom**: Uses UIScrollViewDelegate with `viewForZooming` for smooth pinch-to-zoom
- **Center Preservation**: `zoomToScale` method maintains current view center during programmatic zoom
- **Scroll View Integration**: Direct scroll view manipulation for reliable zoom behavior
- **Pin Tracking**: Pins automatically track with PDF content during zoom/pan via scroll delegate methods
- **Zoom Range**: 0.25x to 4.0x scale with 1.25x increment/decrement steps
- **Real-time Updates**: `scrollViewDidZoom` and `scrollViewDidScroll` ensure pins stay synchronized

#### Spatial Search System
**Phase 7**: Sophisticated area-based search functionality with visual feedback:

- **SpatialSearchOverlay**: Custom UIView for drawing search area selection rectangles
- **Search Mode Toggle**: Activated via viewfinder button in toolbar with visual indicator
- **Area Selection**: Drag-to-select rectangular areas on blueprints with real-time visual feedback
- **Pin Highlighting**: Pins within search area receive accent-colored highlight rings
- **Pin Dimming**: Pins outside search area or categories are dimmed (30% opacity)
- **Results UI**: Horizontal scrollable cards showing matching log entries
- **Coordinate System**: Uses normalized coordinates (0-1) for device independence
- **Category Filtering**: Combined spatial and category-based filtering
- **Visual Feedback**: Semi-transparent overlay with clear/highlighted selection areas
- **Touch Handling**: Sophisticated gesture recognition that doesn't interfere with PDF interaction

### Localization Architecture
**Multi-language Support**: Complete internationalization system with dynamic language switching:

- **LocalizationManager**: Centralized language management with runtime switching capability
- **Supported Languages**: English (default), Spanish, and System (follows device settings)
- **String Organization**: Categorized keys using dot notation (nav.*, project.*, category.*, etc.)
- **Dynamic Updates**: Real-time UI refresh when language changes without app restart
- **Persistent Settings**: User language preference stored in UserDefaults
- **Bundle Management**: Dynamic bundle switching for proper resource loading
- **Translation Files**: Complete `.strings` files for each supported language
- **Extension Integration**: `.localized` string extension for clean code integration
- **Settings UI**: Integrated settings view accessible from main navigation

#### Localization Key Categories
- `general.*` - Common actions (Cancel, Create, Done, etc.)
- `nav.*` - Navigation titles and breadcrumbs
- `project.*` - Project management strings
- `category.*` - Log categories and descriptions
- `filter.*` - Timeline and category filtering
- `log.*` - Log entries and activity tracking
- `blueprint.*` - Blueprint management
- `settings.*` - Configuration options
- `error.*` - Error messages and alerts

#### Usage Patterns
```swift
// Simple localization
"nav.projects".localized

// With format arguments
"log.view_all_entries".localized(args: count)

// Category names (automatic)
category.displayName // Returns localized string
```

### Testing Structure
- **ConstruAppTests**: Unit tests using Swift Testing framework
- **ConstruAppUITests**: UI tests using XCTest and XCUIApplication

### File Organization
```
ConstruApp/
├── Models/
│   ├── Project.swift
│   ├── Blueprint.swift
│   └── LogEntry.swift
├── Views/
│   ├── ProjectListView.swift
│   ├── CreateProjectView.swift
│   ├── ProjectDetailView.swift
│   └── BlueprintViewer/
│       ├── BlueprintViewerView.swift
│       ├── UIKitPDFViewController.swift
│       ├── UIKitPDFViewWrapper.swift
│       ├── PinOverlayView.swift
│       ├── SpatialSearchOverlay.swift
│       ├── AddLogEntryView.swift
│       ├── LogEntryDetailView.swift
│       ├── AddBlueprintView.swift
│       └── InteractivePDFView.swift (legacy - kept for reference)
├── Utilities/
│   ├── SampleDataManager.swift
│   └── LocalizationManager.swift
├── Views/
│   ├── SettingsView.swift
│   ├── TimelineFiltersView.swift
│   └── TimelineView.swift
├── en.lproj/
│   └── Localizable.strings
├── es.lproj/
│   └── Localizable.strings
└── DesignSystem.swift
```

## Key Files and Locations

- Main source code: `ConstruApp/`
- Unit tests: `ConstruAppTests/`
- UI tests: `ConstruAppUITests/`
- Assets: `ConstruApp/Assets.xcassets/`
- Project configuration: `ConstruApp.xcodeproj/`

## Design Guidelines

### Aesthetic Requirements
Given the target audience of architects and designers, the app must prioritize visual excellence:

- **Visual Design**: Clean, professional interface with architect-inspired aesthetics
- **Typography**: Use SF Pro or similar professional typefaces with careful hierarchy
- **Color Palette**: Sophisticated, minimal color scheme (consider architectural blueprints inspiration)
- **Layout**: Grid-based layouts with proper spacing and alignment
- **Icons**: Custom iconography that feels professional and architect-appropriate
- **Animations**: Subtle, purposeful animations that enhance rather than distract
- **Blueprint Presentation**: High-fidelity PDF rendering with smooth zoom/pan interactions

### User Experience Principles
- Prioritize functionality without compromising on beauty
- Every interaction should feel polished and intentional
- Maintain consistency across all views and components
- Design for both iPhone and iPad with responsive layouts

## Critical Implementation Notes

### SwiftData Constraints
- **Never use `description` as a property name** - SwiftData reserves this
- **Always use `projectDescription`** for project description field
- Model container schema includes: `Project.self`, `Blueprint.self`, `LogEntry.self`
- All models use cascade deletion for proper cleanup

### PDF and Coordinate System
- **Coordinate storage is CRITICAL**: Always use normalized coordinates (0-1)
- **Never store absolute pixel coordinates** - they break on different devices/zoom levels
- PDF coordinate system: (0,0) = top-left, (1,1) = bottom-right
- Page numbers start from 1, not 0
- Store PDF dimensions (`pdfWidth`, `pdfHeight`) for accurate coordinate mapping

### Blueprint Viewer Architecture
- **UIKitPDFViewController** is the main PDF controller - pure UIKit for native behavior
- **UIKitPDFViewWrapper** bridges SwiftUI and UIKit using UIViewControllerRepresentable
- **PinOverlayView** handles all pin rendering - uses Core Graphics with scroll view delegate updates
- **Gesture coordination** uses UIKit delegate patterns - properly coordinated with scroll view gestures
- Pin hit testing uses 30pt tap targets (larger than 24pt visual size)
- **Zoom System**: Uses native UIScrollViewDelegate with center-preserving zoom implementation

### Design System Consistency
- **Always use DesignSystem.swift** for colors, fonts, spacing
- **Never hardcode colors or fonts** in individual views
- Use `.cardStyle()` and `.floatingStyle()` view modifiers
- Category colors are defined in LogCategory extension

### Extension Management
- **Color.uiColor()** extension is defined in DesignSystem.swift only
- **LogCategory.color** extension is defined in PinOverlayView.swift
- Don't duplicate extensions across files

## Development Notes

- The project uses automatic code signing with development team VQLSG2U97D
- SwiftUI previews are enabled for development
- Bundle identifier: `com.brippo.contruapp.ConstruApp`
- Supports both iPhone and iPad (device families 1,2)
- Uses file system synchronized groups in Xcode project structure
- **Design-First Approach**: All UI components should be designed with aesthetic excellence as a primary consideration

## Media Gallery System Implementation (Phase 1 - COMPLETED)

### Architecture Overview
The media gallery system provides a hierarchical approach to viewing media across different contexts:

**Core Components Created**:
- **GalleryDataProvider.swift** (`/Utilities/`) - Context-based data fetching and filtering logic
- **MediaGalleryView.swift** (`/Views/Gallery/`) - Main gallery interface with grid layout
- **MediaGalleryItem.swift** (`/Views/Gallery/`) - Individual media item component with thumbnails
- **GalleryFilterBar.swift** (`/Views/Gallery/`) - Filtering interface for date/category/media type
- **MediaDetailView.swift** (`/Views/Gallery/`) - Full-screen media viewer with navigation

### Key Technical Decisions

#### Context-Based Gallery System
```swift
enum GalleryContext {
    case project(Project)
    case blueprint(Blueprint) 
    case spatialArea(Blueprint, bounds: CGRect)
}
```

**CRITICAL**: This context system enables the same UI components to work across all three access levels (project → blueprint → spatial area) with different data scopes.

#### Data Provider Pattern
- **GalleryDataProvider**: Uses SwiftData with manual filtering (avoids complex predicate issues)
- **Lazy Loading**: Media items are extracted and filtered on-demand
- **Thread Safety**: All UI updates happen on MainActor
- **Performance**: Simple FetchDescriptor with manual filtering prevents SwiftData predicate complexity

#### Media Item Structure
```swift
struct GalleryMediaItem {
    let logEntry: LogEntry
    let mediaData: Data
    let mediaType: MediaType (.photo/.video)
    let fileName: String?
}
```

#### Filtering System
```swift
struct GalleryFilter {
    var categories: Set<LogCategory>
    var dateRange: DateInterval?
    var showPhotos: Bool
    var showVideos: Bool
}
```

### Model Extensions Added

#### Project Model (`/Models/Project.swift`)
- `totalMediaItems`, `totalPhotos`, `totalVideos`: Aggregate counts across all blueprints
- `logEntriesWithMedia`: All entries with media, sorted by date
- `mediaByCategory`: Breakdown of media counts by log category

#### Blueprint Model (`/Models/Blueprint.swift`) 
- `totalMediaItems`, `totalPhotos`, `totalVideos`: Blueprint-specific counts
- `logEntriesWithMedia`: Entries with media in this blueprint
- `mediaByCategory`: Category breakdown for this blueprint
- `logEntriesWithMediaInArea(bounds:onPage:)`: Spatial filtering method

#### LogEntry Model (`/Models/LogEntry.swift`)
- `mediaCount`: Total count of photos + video (if present)

### UI Component Architecture

#### MediaGalleryView
- **Grid Layout**: Adaptive columns with 120-200pt item width
- **Loading States**: Progress view with localized messaging
- **Empty States**: Informative empty state with guidance
- **Statistics**: Menu showing media counts by category
- **Navigation**: Context-aware title display

#### MediaGalleryItem  
- **Thumbnail Generation**: Real-time video thumbnail creation using AVAssetImageGenerator
- **Visual Indicators**: Category color dots, media type icons
- **Performance**: 120x120pt fixed size with aspect-fill cropping
- **Accessibility**: Proper tap targets (30pt minimum)

#### GalleryFilterBar
- **Horizontal Scrolling**: Chip-based filter interface
- **Modal Sheets**: Date picker and category selection
- **Real-time Updates**: Immediate filter application
- **Clear Functionality**: Easy filter reset

#### MediaDetailView
- **Full-screen Display**: Black background with overlay controls
- **Navigation**: Swipe/tap navigation between media items
- **Auto-hide Controls**: 3-second timeout with gesture toggle
- **Video Playback**: AVPlayer integration with temporary file handling
- **Info Panel**: Detailed media metadata display

### Localization Integration
**Strings Added** (both English/Spanish):
- Gallery-specific: `gallery.loading_media`, `gallery.no_media_title`, etc.
- Filter-specific: `filter.all_categories`, `filter.select_date_range`, etc.
- General media: `general.photos`, `general.videos`, `general.clear`, etc.

### Critical Implementation Notes

#### Video Thumbnail Generation
- **Temporary Files**: Creates temp URLs for video data processing
- **Cleanup**: Automatic file cleanup after thumbnail generation
- **Performance**: Generates thumbnails at 2x item size for quality
- **Error Handling**: Graceful fallback to placeholder on generation failure

#### Coordinate System Compatibility
- **Spatial Filtering**: Uses existing normalized coordinate system (0-1)
- **Bounds Checking**: Compatible with blueprint viewer coordinate mapping
- **Thread Safety**: All coordinate operations on main thread

#### SwiftData Integration Patterns
- **Manual Filtering**: Avoids complex #Predicate syntax issues
- **Simple Descriptors**: Uses basic FetchDescriptor<LogEntry>()
- **Relationship Traversal**: Manual filtering for project→blueprint→entry relationships
- **Performance**: Acceptable for typical project sizes (hundreds of entries)

#### Design System Compliance
- **Adaptive Colors**: Full ThemeManager integration for light/dark mode
- **Component Reuse**: Uses existing DesignSystem.CornerRadius, Spacing, Typography
- **Visual Consistency**: Follows established card styling patterns
- **Category Colors**: Reuses existing LogCategory color mappings

### Phase 4 Implementation: Spatial Area Gallery Integration (COMPLETED)

#### Overview
Phase 4 successfully integrates the gallery system with the existing spatial search functionality, creating a seamless multi-level media viewing experience. Users can now select areas on blueprints and view only media from those specific coordinate bounds.

#### Key Implementation Components

##### Enhanced BlueprintViewerView (BlueprintViewerView.swift:73-79, 498-513, 515-688)
**Context-Switching Gallery System:**
```swift
private var galleryContext: GalleryContext {
    if let area = searchArea {
        return .spatialArea(blueprint, bounds: area)
    } else {
        return .blueprint(blueprint)
    }
}
```
- **Dynamic Context**: Gallery automatically switches between blueprint-wide and spatial area contexts based on search state
- **Seamless Navigation**: Same gallery interface adapts to different data scopes
- **Coordinate Integration**: Leverages existing normalized coordinate system (0-1)

##### Spatial Media Detection Functions
**Area-Specific Media Counting:**
```swift
private var searchAreaMediaItems: [LogEntry] {
    return searchResults.filter { $0.hasMedia }
}

private var searchAreaMediaCount: (total: Int, photos: Int, videos: Int) {
    let mediaEntries = searchAreaMediaItems
    let photos = mediaEntries.reduce(0) { total, entry in total + entry.photos.count }
    let videos = mediaEntries.reduce(0) { total, entry in total + (entry.videoData != nil ? 1 : 0) }
    return (photos + videos, photos, videos)
}
```
- **Efficient Filtering**: Reuses existing spatial search results for media detection
- **Real-time Updates**: Media counts update automatically when search area changes
- **Multiple Formats**: Provides total, photos, and videos counts separately

##### Enhanced Search Results Overlay (BlueprintViewerView.swift:515-637)
**Media Indicators and Gallery Access:**
- **Media Count Display**: Shows photo/video counts in search results header (lines 532-558)
- **Gallery Button**: Context-aware button that switches between blueprint and spatial area galleries (lines 565-585)
- **Badge Integration**: Consistent badge design matching established patterns
- **Visual Feedback**: Clear indication of media availability within selected areas

##### Media-Aware Search Result Cards (BlueprintViewerView.swift:639-688)
**Individual Entry Indicators:**
- **Media Badges**: Top-right corner badges show photo/video icons for entries with media (lines 658-683)
- **Visual Consistency**: Uses established badge styling patterns
- **User Guidance**: Clear visual indication of which entries contain media

#### Technical Integration Patterns

##### GalleryDataProvider Enhancement
**Spatial Area Context Support:**
- **Coordinate Bounds Filtering**: Handles `.spatialArea(blueprint, bounds: CGRect)` context type
- **Entry Filtering**: Filters log entries by both spatial bounds and category selection
- **Performance Optimized**: Leverages existing coordinate system without additional database queries

##### User Experience Flow
1. **Enter Blueprint Viewer**: Standard blueprint-wide gallery available via toolbar
2. **Enable Search Mode**: Activate spatial search via viewfinder button
3. **Select Area**: Drag to select rectangular area on blueprint
4. **View Results**: Search overlay shows entries and media counts for selected area
5. **Access Gallery**: Gallery button automatically switches to spatial area context
6. **View Media**: Gallery shows only media from selected coordinate bounds
7. **Context Switching**: Gallery seamlessly switches back to blueprint-wide when search is cleared

#### Visual Design Integration

##### Badge Design Consistency
- **Gallery Button Badges**: Consistent with other toolbar button badges
- **Media Count Display**: Follows established count indicator patterns
- **Search Result Badges**: Top-right positioning with primary color background

##### Theme Compatibility
- **Adaptive Colors**: Full integration with ThemeManager for light/dark mode
- **Brand Consistency**: Uses primary/secondary colors from DesignSystem
- **Visual Hierarchy**: Proper color usage for different UI element types

#### Performance Characteristics

##### Efficient Data Flow
- **Coordinate Reuse**: Leverages existing spatial search coordinate calculations
- **Minimal Database Queries**: Uses in-memory filtering of already-loaded data
- **Real-time Updates**: Smooth transitions between contexts without lag

##### Memory Management
- **View State**: Proper state management for search area persistence
- **Context Switching**: Clean transitions without memory leaks
- **UI Updates**: Efficient SwiftUI updates when switching between gallery contexts

#### Integration with Existing Systems

##### Spatial Search System Compatibility
- **Coordinate System**: Full compatibility with existing normalized coordinates (0-1)
- **Search Categories**: Integrates with existing category filtering
- **Visual Feedback**: Enhances existing search overlay without breaking functionality

##### Gallery System Extensions
- **Context Enum**: Extended GalleryContext to support `.spatialArea` type
- **Data Provider**: Enhanced to handle spatial bounds filtering
- **UI Components**: Existing gallery components work seamlessly with new context

#### Critical Success Factors

##### User Experience Achievements
- **Intuitive Navigation**: Natural progression from project → blueprint → spatial area
- **Visual Consistency**: Consistent design language across all gallery levels
- **Performance**: Smooth interactions without noticeable delays
- **Context Awareness**: Clear indication of current gallery scope

##### Technical Robustness
- **Error Handling**: Graceful handling of edge cases (empty areas, no media)
- **State Management**: Proper cleanup when transitioning between contexts
- **Memory Efficiency**: No memory leaks during context switching

### Extension Points for Future Phases

#### Critical Bug Fix: Page-Aware Spatial Filtering
**Issue**: Initial implementation of spatial area gallery showed all blueprint media instead of only media from the selected area on the current page.

**Root Cause**: `GalleryDataProvider` filtered by spatial coordinates but didn't account for page numbers, while `BlueprintViewerView` spatial search was page-specific.

**Solution Implemented** (GalleryDataProvider.swift:15, 136-150 & BlueprintViewerView.swift:73-79):
1. **Enhanced Context**: Extended `GalleryContext.spatialArea` to include page number parameter
2. **Page Filtering**: Added `entry.pageNumber == page` filter in spatial area data fetching
3. **Context Integration**: Updated `BlueprintViewerView` to pass `currentPage` to spatial area context

**Result**: Spatial area gallery now correctly shows only media from log entries within the selected coordinate bounds on the current page, matching the spatial search overlay behavior exactly.

#### Critical UX Fix: Context-Aware Gallery Button
**Issue**: The main toolbar gallery button always showed blueprint-wide media count and opened blueprint-wide gallery, even when user had selected a spatial area for focused viewing.

**Root Cause**: Gallery button was hardcoded to use `blueprint.totalMediaItems` and didn't respond to spatial search state changes.

**Solution Implemented** (BlueprintViewerView.swift:81-88, 162-182):
1. **Context-Aware Media Count**: Added `currentGalleryMediaCount` computed property that returns spatial area media count when in search mode, blueprint-wide count otherwise
2. **Dynamic Button State**: Gallery button now shows/hides based on current context media availability
3. **Unified Experience**: Removed duplicate gallery button from search overlay, making main toolbar button the single source of gallery access
4. **Seamless Context Switching**: Same button automatically switches between blueprint and spatial area galleries based on user's current focus

**Result**: Users now see consistent, context-aware gallery access - when they select an area and see "1 log entry" with media, the gallery button shows "1" and opens spatial area gallery with only that entry's media. When they clear the search, it returns to blueprint-wide gallery behavior.

#### Phase 5 Ready Features
- **Advanced Filtering**: Smart date filtering and search functionality ready for implementation
- **Media Statistics**: Detailed analytics views for media usage patterns
- **Export Functionality**: Foundation for exporting media from specific areas
- **Enhanced Visualization**: Ready for advanced media preview features

#### Performance Optimizations Available
- **Pagination**: GalleryDataProvider supports batch loading
- **Caching**: Thumbnail cache system can be added
- **Background Loading**: Async thumbnail generation ready

#### Filter Enhancements Ready
- **Smart Dates**: "Last week", "This month" presets can be added
- **Combined Filters**: Multiple category selection working
- **Search**: Text search in titles/notes infrastructure ready

**NEVER MODIFY**: The coordinate system (0-1 normalized), the GalleryContext enum structure, or the core filtering logic without understanding impact on future phases.

## Media Gallery Integration - Phase 2: Project-Level Gallery (COMPLETED)

### Implementation Overview
Project-level gallery integration provides users with access to all media across all blueprints in a project from the main project detail view.

### Key Implementation Changes

#### ProjectDetailView Integration (`/Views/ProjectDetailView.swift`)

**Gallery Button in Toolbar**:
```swift
// Toolbar with gallery access
HStack(spacing: DesignSystem.Spacing.sm) {
    Button(action: { showingGallery = true }) {
        Image(systemName: "photo.on.rectangle.angled")
            .foregroundColor(DesignSystem.Colors.primary)
    }
    .disabled(project.totalMediaItems == 0)
    // ... existing menu
}
```

**Navigation Integration**:
```swift
.sheet(isPresented: $showingGallery) {
    MediaGalleryView(context: .project(project), modelContext: modelContext)
}
```

**CRITICAL**: The gallery button is automatically disabled when `project.totalMediaItems == 0`, providing clear UX feedback when no media is available.

#### Enhanced Statistics Display

**Media Statistics Cards**:
- **Conditional Display**: Media stats only appear when `project.totalMediaItems > 0`
- **Three-Card Layout**: Photos count, Videos count, and clickable Gallery access card
- **Interactive Gallery Card**: Tapping the media gallery card opens the full gallery view
- **Visual Hierarchy**: Media cards use slightly transparent brand colors for distinction

#### Blueprint List Enhancements

**Media Indicators in BlueprintRowView**:
```swift
// Enhanced blueprint info with media counts
Text("\(blueprint.logEntries.count) logs") 
if blueprint.totalMediaItems > 0 {
    HStack {
        if blueprint.totalPhotos > 0 {
            Image(systemName: "photo") + Text("\(blueprint.totalPhotos)")
        }
        if blueprint.totalVideos > 0 {
            Image(systemName: "video") + Text("\(blueprint.totalVideos)")
        }
    }
}
Text("• \(blueprint.fileSize)")
```

**User Experience Benefits**:
- **At-a-glance Media Overview**: Users can see which blueprints contain media without opening them
- **Visual Differentiation**: Media counts are colored with brand accent to draw attention
- **Compact Display**: Icons and counts are sized to fit within existing blueprint row layout

### Localization Additions

**New Navigation Strings** (English/Spanish):
- `nav.media_gallery` = "Media Gallery" / "Galería de Medios"
- `nav.blueprint` = "Blueprint" / "Plano"

### Technical Implementation Notes

#### State Management
- **Gallery State**: New `@State private var showingGallery = false` added to ProjectDetailView
- **Context Creation**: Uses `MediaGalleryView(context: .project(project), modelContext: modelContext)`
- **Model Integration**: Leverages existing `project.totalMediaItems`, `project.totalPhotos`, `project.totalVideos` computed properties

#### UI Responsiveness
- **Dynamic Layout**: Statistics section adapts from single row to two rows when media is present
- **Conditional Rendering**: Media statistics only appear when project has media content
- **Button States**: Gallery button disabled state provides clear visual feedback

#### Performance Considerations
- **Lazy Evaluation**: Media counts are computed properties that calculate on-demand
- **No Additional Queries**: Uses existing SwiftData relationships without extra database hits
- **Sheet Presentation**: Gallery opens in sheet for smooth navigation without losing project context

### Integration Patterns Established

#### Gallery Context Usage
```swift
// Project-level gallery access
MediaGalleryView(context: .project(project), modelContext: modelContext)
```

This establishes the pattern that will be replicated for:
- Blueprint-level: `context: .blueprint(blueprint)`
- Spatial-level: `context: .spatialArea(blueprint, bounds)`

#### Toolbar Integration Pattern
The toolbar pattern with conditional button states can be reused in BlueprintViewerView:
```swift
Button(action: { showingGallery = true }) {
    Image(systemName: "photo.on.rectangle.angled")
}
.disabled(mediaCount == 0)
```

#### Statistics Card Pattern
The media statistics card pattern is reusable for blueprint-level statistics and can be extended with category breakdowns.

### User Journey Integration

#### From Project Detail → Gallery
1. **User sees project statistics** including media counts if present
2. **Multiple access points**: Toolbar button or statistics card tap
3. **Gallery opens** showing all media from all project blueprints
4. **Filtering available** by category, date, media type
5. **Full-screen viewing** with navigation between media items
6. **Context preservation** via sheet presentation

#### Visual Feedback Hierarchy
- **No Media**: Gallery button disabled, no media statistics shown
- **Has Media**: Gallery button active, media stats cards visible with counts
- **Blueprint Level**: Individual blueprint rows show media indicators

### Accessibility Considerations
- **Button States**: Disabled gallery button provides clear affordance
- **Visual Hierarchy**: Media counts use appropriate contrast ratios
- **Touch Targets**: All interactive elements maintain minimum 44pt touch targets

### Extension Points for Phase 3
- **Blueprint Context**: Ready for `MediaGalleryView(context: .blueprint(blueprint))`
- **Toolbar Pattern**: Established pattern for BlueprintViewerView integration
- **Statistics Pattern**: Can be extended with category-specific breakdowns
- **Navigation Pattern**: Sheet presentation pattern established for consistency

**NEVER MODIFY**: The `GalleryContext.project(project)` usage pattern - this is critical for the multi-level gallery system architecture.

## Media Gallery Integration - Phase 3: Blueprint-Level Gallery (COMPLETED)

### Implementation Overview
Blueprint-level gallery integration provides direct access to media within a specific blueprint from the blueprint viewer interface, with enhanced UI indicators showing per-page media statistics.

### Key Implementation Changes

#### BlueprintViewerView Integration (`/Views/BlueprintViewer/BlueprintViewerView.swift`)

**Gallery Button with Media Badge**:
```swift
// Conditional gallery button in toolbar
if blueprint.totalMediaItems > 0 {
    Button(action: { showingGallery = true }) {
        ZStack {
            Image(systemName: "photo.on.rectangle.angled")
                .foregroundColor(DesignSystem.Colors.primary)
            
            // Media count badge
            Circle()
                .fill(DesignSystem.Colors.primary)
                .frame(width: 16, height: 16)
                .overlay(Text("\(blueprint.totalMediaItems)"))
                .offset(x: 8, y: -8)
        }
    }
}
```

**Navigation Integration**:
```swift
.sheet(isPresented: $showingGallery) {
    MediaGalleryView(context: .blueprint(blueprint), modelContext: modelContext)
}
```

**CRITICAL**: The gallery button only appears when `blueprint.totalMediaItems > 0`, maintaining clean UI when no media exists. The badge shows total media count for immediate visual feedback.

#### Enhanced Page Controls with Media Statistics

**Current Page Media Counter**:
```swift
private var currentPageMediaCount: (photos: Int, videos: Int) {
    let entriesOnPage = blueprint.logEntriesOnPage(currentPage)
    let photos = entriesOnPage.reduce(0) { total, entry in
        total + entry.photos.count
    }
    let videos = entriesOnPage.reduce(0) { total, entry in
        total + (entry.videoData != nil ? 1 : 0)
    }
    return (photos, videos)
}
```

**Enhanced Page Indicator Display**:
- **Base Info**: Shows "Page X of Y" as before
- **Media Indicators**: Adds photo/video counts for current page when present
- **Visual Distinction**: Media counts use brand accent color to differentiate from page info
- **Compact Layout**: Icons and numbers sized appropriately for floating controls

#### Menu Integration

**Conditional Menu Item**:
```swift
if blueprint.totalMediaItems > 0 {
    Button(action: { showingGallery = true }) {
        Label("nav.media_gallery".localized, systemImage: "photo.on.rectangle.angled")
    }
    Divider()
}
```

**User Experience Benefits**:
- **Multiple Access Points**: Both toolbar button and menu option for flexibility
- **Context Preservation**: Users remain in blueprint viewer when gallery closes
- **Immediate Media Context**: Badge shows total blueprint media, page controls show current page media

### Technical Implementation Notes

#### State Management
- **Gallery State**: Added `@State private var showingGallery = false` to BlueprintViewerView
- **Context Usage**: `MediaGalleryView(context: .blueprint(blueprint), modelContext: modelContext)`
- **Real-time Updates**: Page media counts update automatically when changing pages

#### UI Responsiveness
- **Conditional Rendering**: Gallery elements only appear when media exists
- **Badge Integration**: Media count badge overlays gallery icon for visual prominence
- **Page-Level Granularity**: Media indicators show current page context, not just total

#### Performance Considerations
- **Efficient Calculation**: Media counts calculated using existing `logEntriesOnPage` method
- **Minimal Overhead**: Uses existing SwiftData relationships without additional queries
- **Per-Page Calculation**: Page media counts computed on-demand when page changes

### Integration with Existing Features

#### Toolbar Density Management
- **Strategic Placement**: Gallery button positioned after log count indicator
- **Visual Hierarchy**: Gallery button uses consistent styling with other toolbar elements
- **Space Efficiency**: Badge design maximizes information density without overwhelming UI

#### Coordinate System Compatibility
- **Existing Workflow**: Gallery integration doesn't interfere with pin placement or spatial search
- **Context Switching**: Users can switch between gallery and blueprint interaction seamlessly
- **Data Consistency**: Gallery shows same media attached to blueprint pins

### User Journey Integration

#### From Blueprint Viewer → Gallery
1. **User opens blueprint** and sees media badge on gallery button (if media exists)
2. **Page navigation** shows per-page media counts in floating controls
3. **Gallery access** via toolbar button or menu, filtered to current blueprint only
4. **Media browsing** with all filtering options available for blueprint scope
5. **Return to blueprint** with context preserved (same page, zoom level)

#### Visual Information Hierarchy
- **Blueprint Level**: Gallery button badge shows total blueprint media count
- **Page Level**: Page controls show current page media breakdown (photos/videos)
- **Pin Level**: Individual pins show category colors and media type indicators (existing)

### Accessibility and Usability

#### Visual Clarity
- **Clear Affordances**: Gallery button only appears when actionable
- **Information Density**: Media counts provide immediate context without cluttering
- **Consistent Patterns**: Uses same design patterns as project-level integration

#### Touch Target Optimization
- **Button Size**: Gallery button maintains minimum 44pt touch target
- **Badge Placement**: Badge positioned to avoid accidental activation while remaining visible
- **Menu Alternative**: Menu option provides alternative access for different interaction preferences

### Extension Points for Phase 4

#### Spatial Context Ready
- **Coordinate Integration**: Current implementation ready for spatial area bounds detection
- **Page Context**: Page-level media counts can inform spatial search areas
- **Zoom Context**: Gallery button state could adapt based on current zoom level

#### Enhanced Filtering
- **Page-Specific Filtering**: Gallery could pre-filter to current page when opened from blueprint viewer
- **Category Context**: Could pre-select categories based on visible pins in current view
- **Temporal Context**: Could highlight recent media based on blueprint viewing patterns

### Technical Patterns Established

#### Gallery Context Usage
```swift
// Blueprint-level gallery access
MediaGalleryView(context: .blueprint(blueprint), modelContext: modelContext)
```

This pattern is consistent with project-level and ready for spatial-level:
- Project: `context: .project(project)`
- Blueprint: `context: .blueprint(blueprint)`
- Spatial: `context: .spatialArea(blueprint, bounds)`

#### Media Statistics Integration
The per-page media counting pattern can be extended for spatial areas:
```swift
private var currentPageMediaCount: (photos: Int, videos: Int) {
    // Can be adapted for spatial bounds calculation
}
```

#### Badge Design Pattern
The gallery button badge pattern establishes a reusable component for showing media counts:
- **Consistent Sizing**: 16pt diameter circle with white text
- **Standard Offset**: (x: 8, y: -8) positioning
- **Brand Colors**: Uses primary brand color for consistency

### Coordinate System Preservation
- **No Impact**: Gallery integration doesn't modify existing coordinate handling
- **Context Aware**: Gallery shows media based on blueprint's coordinate system
- **Pin Compatibility**: Gallery media items link back to their pin locations

**NEVER MODIFY**: The blueprint viewer's coordinate handling, pin overlay system, or spatial search functionality when working with gallery features.

## Current Blueprint PDF and Coordinate System Implementation

### Architecture Overview
The blueprint viewer uses a **pure UIKit approach** wrapped in SwiftUI for optimal performance and native behavior:

- **UIKitPDFViewController**: Main PDF controller handling all PDF operations, zoom, and pan
- **UIKitPDFViewWrapper**: SwiftUI wrapper using `UIViewControllerRepresentable`
- **PinOverlayView**: Overlay constrained to PDFView bounds for automatic content tracking
- **Coordinate System**: Direct PDFKit coordinate conversion with proper Y-axis handling

### Coordinate System Details
- **Storage**: Normalized coordinates (0.0 to 1.0) for device independence
- **Conversion**: `pdfView.convert(pdfPoint, from: currentPage)` for accurate positioning
- **Y-Axis**: Automatic flipping between PDF (bottom-left origin) and UIKit (top-left origin)
- **Pin Tracking**: Pins automatically move with PDF content via scroll view delegate methods

### Key Methods and Files
- **UIKitPDFViewController.swift**: `handleTap` method for coordinate conversion from touch to normalized
- **PinOverlayView.swift**: `convertLogEntryToViewCoordinates` for pin positioning
- **BlueprintViewerView.swift**: `GlobalCoordinateStore` singleton class for persistent coordinate storage
- **Scroll Delegates**: `scrollViewDidScroll`, `scrollViewDidZoom` for real-time pin updates
- **Zoom Implementation**: `zoomToScale` method with center-preserving behavior
- **Coordinate Storage**: `GlobalCoordinateStore.shared.store()` and `GlobalCoordinateStore.shared.retrieve()`

### Why This Architecture
This approach solves previous issues:
- ✅ **Center-preserving zoom**: Native UIKit scroll view behavior
- ✅ **Accurate pin placement**: Direct PDFKit coordinate conversion
- ✅ **Pin tracking**: Automatic movement with PDF content during pan/scroll
- ✅ **Pinch-to-zoom**: Native gesture recognition without conflicts
- ✅ **First-tap reliability**: GlobalCoordinateStore survives SwiftUI view reconstructions
- ✅ **Coordinate persistence**: Dual storage prevents coordinate loss during state resets

### First Tap Coordinate Issue Fix
**Problem**: The first tap after entering a blueprint screen resulted in 0.0% 0.0% coordinates while subsequent taps worked correctly.

**Root Cause**: SwiftUI view reconstruction occurring between the tap callback and sheet presentation on first tap, causing all `@State` variables to reset to initial values (0.0, 0.0).

**Solution Implemented** (`BlueprintViewerView.swift:12-32, 76-77, 228-233`):
1. **GlobalCoordinateStore**: Singleton class that stores coordinates outside SwiftUI state system, surviving view reconstructions
2. **Dual Storage**: Coordinates stored in both SwiftUI state variables and global store for redundancy
3. **Priority Fallback**: Sheet presentation uses GlobalCoordinateStore first, then falls back to state variables
4. **Debug Tracking**: Comprehensive logging shows coordinate flow from callback to sheet presentation
5. **Cleanup**: GlobalCoordinateStore cleared when sheet dismisses to prevent stale data

**Key Implementation**:
- **Storage**: `GlobalCoordinateStore.shared.store(point)` in tap callback
- **Retrieval**: `GlobalCoordinateStore.shared.retrieve()` in sheet presentation
- **Fallback**: `globalCoords != CGPoint.zero ? globalCoords : stateCoords`

This ensures the first tap after entering a blueprint always gets proper coordinates instead of defaulting to 0.0, 0.0.

## Localization Guidelines

### Adding New Strings
When adding any user-facing text to the app:

1. **Never hardcode strings** - Use localization keys instead
2. **Add to both language files** - Update both `en.lproj/Localizable.strings` and `es.lproj/Localizable.strings`
3. **Follow naming conventions** - Use descriptive dot notation keys (e.g., `project.create_button`)
4. **Use .localized extension** - `"key.name".localized` for simple strings
5. **Format with arguments** - `"key.name".localized(args: value)` for dynamic content

### Key Naming Conventions
- Use existing categories: `general.*`, `nav.*`, `project.*`, `category.*`, `filter.*`, `log.*`, `blueprint.*`, `settings.*`, `error.*`
- Be descriptive: `project.create_button` not `create`
- Use consistent terminology: `project.name` not `proj.title`
- Group related strings: All navigation titles under `nav.*`

### Translation Guidelines
- **Spanish translations** should be professionally appropriate for construction industry
- **Maintain consistency** in terminology across the app
- **Consider text length** differences - Spanish text is typically 20-30% longer
- **Test on different screen sizes** after adding translations
- **Use formal language** appropriate for professional users (architects, contractors)

### LocalizationManager Usage
- **Runtime language changes**: Users can switch languages without app restart
- **Persistent preferences**: Language choice is saved automatically
- **System integration**: "System" option follows device language
- **Thread safety**: All localization calls are thread-safe

## Light/Dark Mode Strategy

### Architecture Overview
The app uses a comprehensive theme management system with adaptive colors that automatically respond to system appearance changes or user preference overrides.

### Key Components
- **ThemeManager.swift**: Central theme management with `AppTheme` enum (.light, .dark, .system)
- **Adaptive Colors**: All colors defined through `ThemeManager.shared.adaptiveColor()` 
- **Semantic Naming**: Colors named by purpose (primaryText, secondaryText) not appearance (black, white)

### Critical Color Usage Rules

#### ✅ **ALWAYS Use These for Text:**
- `DesignSystem.Colors.primaryText` - Main text content, titles, headers
- `DesignSystem.Colors.secondaryText` - Supporting text, captions, metadata
- `DesignSystem.Colors.placeholderText` - Form placeholders and disabled text
- `DesignSystem.Colors.buttonText` - Text on colored button backgrounds

#### ✅ **ALWAYS Use These for UI Elements:**
- `DesignSystem.Colors.primary` - Brand elements, interactive buttons, accent elements
- `DesignSystem.Colors.secondary` - Supporting brand color for visual hierarchy
- `DesignSystem.Colors.background` - Main app background
- `DesignSystem.Colors.secondaryBackground` - Card/section backgrounds
- `DesignSystem.Colors.cardBackground` - Elevated card surfaces

#### ❌ **NEVER Use These Patterns:**
```swift
// DON'T: Using brand colors for body text
.foregroundColor(DesignSystem.Colors.primary)  // Will appear dark in dark mode

// DON'T: Hardcoded colors
.foregroundColor(.black)
.foregroundColor(.white)
.background(Color.gray)

// DON'T: Static color references
.foregroundColor(DesignSystem.Colors.architectGray)  // Legacy static colors
```

#### ✅ **DO Use These Patterns:**
```swift
// DO: Semantic text colors
.foregroundColor(DesignSystem.Colors.primaryText)    // Adapts to theme
.foregroundColor(DesignSystem.Colors.secondaryText)  // Adapts to theme

// DO: Semantic backgrounds
.background(DesignSystem.Colors.cardBackground)      // Adapts to theme

// DO: Brand colors for interactive elements
Button("Action") { }
.foregroundColor(DesignSystem.Colors.primary)        // Always brand color
```

### Text Color Decision Matrix

| Element Type | Light Mode | Dark Mode | DesignSystem Color |
|--------------|------------|-----------|-------------------|
| Titles & Headers | Dark | Light | `.primaryText` |
| Body Text | Dark | Light | `.primaryText` |
| Supporting Text | Gray | Light Gray | `.secondaryText` |
| Button Text on Colored BG | White | White | `.buttonText` |
| Interactive Elements | Brand Blue | Brand Blue | `.primary` |
| Placeholders | Light Gray | Dark Gray | `.placeholderText` |

### Theme Switching Implementation
- **User Setting**: Stored in UserDefaults, managed by ThemeManager
- **Real-time Updates**: Uses `@ObservableObject` pattern for reactive UI updates
- **System Integration**: Respects user's system-wide appearance preference when set to "System"

### Testing Dark Mode
Always test these scenarios:
1. **App launch in dark mode** - All screens should display properly
2. **Theme switching while app is running** - UI should update immediately
3. **System appearance changes** - App should follow when set to "System"
4. **All major screens** - ProjectList, Blueprint Viewer, Timeline, Settings

### Legacy Color Migration
- All static colors in DesignSystem are marked `@available(*, deprecated)`
- Use compiler warnings to identify usage of deprecated colors
- Replace with appropriate adaptive colors based on semantic meaning

## Common Pitfalls to Avoid

1. **Don't break coordinate system**: Normalized coordinates are essential for cross-device compatibility
2. **Don't revert to SwiftUI+UIKit hybrid**: The pure UIKit approach is required for reliable zoom/pan
3. **Don't ignore SwiftData naming**: `description` property will cause build failures
4. **Don't hardcode styling**: Always use DesignSystem tokens
5. **Don't modify scroll view delegates**: Pin tracking depends on `scrollViewDidScroll` and `scrollViewDidZoom`
6. **Don't store absolute coordinates**: Always normalize to 0-1 range before storage
7. **Don't change pin overlay constraints**: Overlay must be constrained to PDFView for proper tracking
8. **Don't use brand colors for text content**: Use `primaryText`/`secondaryText`, not `primary`/`secondary`
9. **Don't hardcode .black/.white colors**: Always use semantic adaptive colors
8. **Don't hardcode user-facing strings**: Always use `.localized` extension for all UI text
9. **Don't modify LocalizationManager lightly**: String localization system is critical for user experience
10. **Don't add strings without translations**: All new keys must be added to both English and Spanish .strings files