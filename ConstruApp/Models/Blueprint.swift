//
//  Blueprint.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import Foundation
import SwiftData

@Model
final class Blueprint {
    var id: UUID
    var name: String
    var fileName: String
    var pdfData: Data
    var uploadDate: Date
    var pageCount: Int
    var currentPage: Int
    
    // PDF dimensions for coordinate mapping
    var pdfWidth: Double
    var pdfHeight: Double
    
    // Relationships
    var project: Project?
    
    @Relationship(deleteRule: .cascade, inverse: \LogEntry.blueprint)
    var logEntries: [LogEntry] = []
    
    init(
        name: String,
        fileName: String,
        pdfData: Data,
        pageCount: Int,
        pdfWidth: Double,
        pdfHeight: Double
    ) {
        self.id = UUID()
        self.name = name
        self.fileName = fileName
        self.pdfData = pdfData
        self.uploadDate = Date()
        self.pageCount = pageCount
        self.currentPage = 1
        self.pdfWidth = pdfWidth
        self.pdfHeight = pdfHeight
    }
    
    var fileSize: String {
        let bytes = Double(pdfData.count)
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func logEntriesOnPage(_ page: Int) -> [LogEntry] {
        return logEntries.filter { $0.pageNumber == page }
    }
    
    func logEntriesOfCategory(_ category: LogCategory, onPage page: Int? = nil) -> [LogEntry] {
        var filtered = logEntries.filter { $0.category == category }
        if let page = page {
            filtered = filtered.filter { $0.pageNumber == page }
        }
        return filtered.sorted { $0.date > $1.date }
    }
    
    func logEntriesNear(x: Double, y: Double, radius: Double, onPage page: Int) -> [LogEntry] {
        return logEntries.filter { entry in
            entry.pageNumber == page &&
            sqrt(pow(entry.xCoordinate - x, 2) + pow(entry.yCoordinate - y, 2)) <= radius
        }
    }
    
    // MARK: - Media Properties
    
    /// Total number of media items (photos + videos) in this blueprint
    var totalMediaItems: Int {
        logEntries.reduce(0) { total, entry in
            total + entry.mediaCount
        }
    }
    
    /// Total number of photos in this blueprint
    var totalPhotos: Int {
        logEntries.reduce(0) { total, entry in
            total + entry.photos.count
        }
    }
    
    /// Total number of videos in this blueprint
    var totalVideos: Int {
        logEntries.reduce(0) { total, entry in
            total + (entry.videoData != nil ? 1 : 0)
        }
    }
    
    /// Log entries that have at least one media item (photo or video)
    var logEntriesWithMedia: [LogEntry] {
        return logEntries.filter { entry in
            !entry.photos.isEmpty || entry.videoData != nil
        }
    }
    
    /// Media count breakdown by category
    var mediaByCategory: [LogCategory: Int] {
        var breakdown: [LogCategory: Int] = [:]
        
        for entry in logEntries {
            let mediaCount = entry.mediaCount
            if mediaCount > 0 {
                breakdown[entry.category, default: 0] += mediaCount
            }
        }
        
        return breakdown
    }
    
    /// Log entries within a spatial area that have media
    func logEntriesWithMediaInArea(bounds: CGRect, onPage page: Int? = nil) -> [LogEntry] {
        let entriesInArea = logEntries.filter { entry in
            // Check if within bounds
            let inBounds = entry.xCoordinate >= bounds.minX && 
                          entry.xCoordinate <= bounds.maxX &&
                          entry.yCoordinate >= bounds.minY && 
                          entry.yCoordinate <= bounds.maxY
            
            // Check page if specified
            let onCorrectPage = page == nil || entry.pageNumber == page
            
            // Check has media
            let hasMedia = !entry.photos.isEmpty || entry.videoData != nil
            
            return inBounds && onCorrectPage && hasMedia
        }
        
        return entriesInArea.sorted { $0.date > $1.date }
    }
}