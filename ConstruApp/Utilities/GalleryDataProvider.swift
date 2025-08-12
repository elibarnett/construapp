//
//  GalleryDataProvider.swift
//  ConstruApp
//
//  Created by Claude on 8/11/25.
//

import SwiftUI
import SwiftData

/// Defines the context for gallery data fetching
enum GalleryContext {
    case project(Project)
    case blueprint(Blueprint)
    case spatialArea(Blueprint, bounds: CGRect, page: Int)
    
    var title: String {
        switch self {
        case .project(let project):
            return project.name
        case .blueprint(let blueprint):
            return blueprint.name
        case .spatialArea(let blueprint, _, let page):
            return "\(blueprint.name) - Page \(page) Area"
        }
    }
}

/// Filter options for gallery content
struct GalleryFilter {
    var categories: Set<LogCategory>
    var dateRange: DateInterval?
    var showPhotos: Bool
    var showVideos: Bool
    
    static var all: GalleryFilter {
        GalleryFilter(
            categories: Set(LogCategory.allCases),
            dateRange: nil,
            showPhotos: true,
            showVideos: true
        )
    }
}

/// Represents a media item in the gallery
struct GalleryMediaItem: Identifiable {
    let id = UUID()
    let logEntry: LogEntry
    let mediaData: Data
    let mediaType: MediaType
    let fileName: String?
    
    enum MediaType {
        case photo
        case video
    }
    
    var date: Date {
        logEntry.date
    }
    
    var category: LogCategory {
        logEntry.category
    }
    
    var title: String {
        logEntry.title.isEmpty ? "category.\(logEntry.category.rawValue)".localized : logEntry.title
    }
    
    var blueprintName: String {
        logEntry.blueprint?.name ?? "Unknown Blueprint"
    }
}

/// Provides data for the media gallery based on context and filters
@Observable
class GalleryDataProvider {
    private let modelContext: ModelContext
    private var _mediaItems: [GalleryMediaItem] = []
    private var _isLoading = false
    
    var mediaItems: [GalleryMediaItem] { _mediaItems }
    var isLoading: Bool { _isLoading }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Loads media items for the given context and filter
    @MainActor
    func loadMedia(for context: GalleryContext, filter: GalleryFilter = .all) {
        print("🔄 DEBUG: GalleryDataProvider.loadMedia called")
        print("🔄 DEBUG: Context: \(context)")
        print("🔄 DEBUG: Filter: \(filter)")
        
        _isLoading = true
        
        Task {
            do {
                let logEntries = try fetchLogEntries(for: context)
                print("📦 DEBUG: Fetched \(logEntries.count) log entries for context")
                
                let filteredEntries = applyFilter(filter, to: logEntries)
                print("🔍 DEBUG: After applying filter: \(filteredEntries.count) entries remain")
                
                let mediaItems = extractMediaItems(from: filteredEntries)
                print("🖼️ DEBUG: Extracted \(mediaItems.count) media items")
                
                await MainActor.run {
                    self._mediaItems = mediaItems.sorted { $0.date > $1.date }
                    self._isLoading = false
                    print("✅ DEBUG: Gallery loading complete - \(self._mediaItems.count) media items loaded")
                }
            } catch {
                await MainActor.run {
                    print("❌ ERROR: Loading gallery media: \(error)")
                    self._mediaItems = []
                    self._isLoading = false
                }
            }
        }
    }
    
    /// Fetches log entries based on gallery context
    private func fetchLogEntries(for context: GalleryContext) throws -> [LogEntry] {
        switch context {
        case .project(let project):
            // Get all log entries from all blueprints in the project
            // Fetch all log entries and filter manually to avoid complex predicate issues
            let descriptor = FetchDescriptor<LogEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            return allEntries.filter { entry in
                entry.blueprint?.project == project
            }
            
        case .blueprint(let blueprint):
            // Get all log entries from the specific blueprint
            // Use a simple fetch and manual filter to avoid SwiftData predicate issues
            let descriptor = FetchDescriptor<LogEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            return allEntries.filter { entry in
                entry.blueprint == blueprint
            }
            
        case .spatialArea(let blueprint, let bounds, let page):
            // Get log entries within the spatial bounds on the specific page
            print("🎯 DEBUG: fetchLogEntries for spatialArea")
            print("🎯 DEBUG: - Blueprint: \(blueprint.name)")
            print("🎯 DEBUG: - Page: \(page)")
            print("🎯 DEBUG: - Bounds: \(bounds)")
            
            let descriptor = FetchDescriptor<LogEntry>()
            let allEntries = try modelContext.fetch(descriptor)
            print("🎯 DEBUG: - Total entries in database: \(allEntries.count)")
            
            // Filter by blueprint, page number, and spatial bounds (normalized coordinates)
            let filteredEntries = allEntries.filter { entry in
                let matchesBlueprint = entry.blueprint == blueprint
                let matchesPage = entry.pageNumber == page
                let x = entry.xCoordinate
                let y = entry.yCoordinate
                let withinBounds = x >= bounds.minX && x <= bounds.maxX &&
                                  y >= bounds.minY && y <= bounds.maxY
                
                print("🎯 DEBUG: Entry '\(entry.title)' - blueprint:\(matchesBlueprint), page:\(matchesPage), bounds:\(withinBounds) (x:\(x), y:\(y))")
                
                return matchesBlueprint && matchesPage && withinBounds
            }
            
            print("🎯 DEBUG: - Spatial area filtered entries: \(filteredEntries.count)")
            return filteredEntries
        }
    }
    
    /// Applies filter criteria to log entries
    private func applyFilter(_ filter: GalleryFilter, to entries: [LogEntry]) -> [LogEntry] {
        print("🔍 DEBUG: applyFilter called with \(entries.count) entries")
        print("🔍 DEBUG: Filter categories: \(filter.categories.count) of \(LogCategory.allCases.count)")
        print("🔍 DEBUG: Filter dateRange: \(filter.dateRange?.description ?? "nil")")
        print("🔍 DEBUG: Filter showPhotos: \(filter.showPhotos), showVideos: \(filter.showVideos)")
        
        return entries.filter { entry in
            // Filter by category
            let categoryMatch = filter.categories.contains(entry.category)
            if !categoryMatch {
                print("🔍 DEBUG: Entry '\(entry.title)' filtered out by category (\(entry.category.rawValue))")
                return false
            }
            
            // Filter by date range
            if let dateRange = filter.dateRange {
                let dateMatch = dateRange.contains(entry.date)
                if !dateMatch {
                    print("🔍 DEBUG: Entry '\(entry.title)' filtered out by date (\(entry.date) not in \(dateRange))")
                    return false
                }
            }
            
            // Filter by media type availability
            let hasPhotos = !entry.photos.isEmpty
            let hasVideos = entry.videoData != nil
            let hasMediaOfRequiredType = (filter.showPhotos && hasPhotos) || 
                                       (filter.showVideos && hasVideos)
            
            if !hasMediaOfRequiredType {
                print("🔍 DEBUG: Entry '\(entry.title)' filtered out by media type (photos:\(hasPhotos), videos:\(hasVideos))")
                return false
            }
            
            print("🔍 DEBUG: Entry '\(entry.title)' PASSED all filters")
            return true
        }
    }
    
    /// Extracts individual media items from log entries
    private func extractMediaItems(from entries: [LogEntry]) -> [GalleryMediaItem] {
        var mediaItems: [GalleryMediaItem] = []
        
        for entry in entries {
            // Add photos
            for (index, photoData) in entry.photos.enumerated() {
                let item = GalleryMediaItem(
                    logEntry: entry,
                    mediaData: photoData,
                    mediaType: .photo,
                    fileName: "photo_\(index + 1).jpg"
                )
                mediaItems.append(item)
            }
            
            // Add video
            if let videoData = entry.videoData,
               let videoFileName = entry.videoFileName {
                let item = GalleryMediaItem(
                    logEntry: entry,
                    mediaData: videoData,
                    mediaType: .video,
                    fileName: videoFileName
                )
                mediaItems.append(item)
            }
        }
        
        return mediaItems
    }
    
    /// Returns statistics about the loaded media
    var mediaStatistics: (totalItems: Int, photoCount: Int, videoCount: Int, categoryBreakdown: [LogCategory: Int]) {
        let totalItems = mediaItems.count
        let photoCount = mediaItems.filter { $0.mediaType == .photo }.count
        let videoCount = mediaItems.filter { $0.mediaType == .video }.count
        
        let categoryBreakdown = Dictionary(grouping: mediaItems) { $0.category }
            .mapValues { $0.count }
        
        return (totalItems, photoCount, videoCount, categoryBreakdown)
    }
}