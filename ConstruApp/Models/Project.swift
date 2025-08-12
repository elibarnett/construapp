//
//  Project.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var projectDescription: String
    var clientName: String
    var location: String
    var createdDate: Date
    var lastModifiedDate: Date
    var isArchived: Bool
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Blueprint.project)  
    var blueprints: [Blueprint] = []
    
    init(
        name: String,
        description: String = "",
        clientName: String = "",
        location: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.projectDescription = description
        self.clientName = clientName
        self.location = location
        self.createdDate = Date()
        self.lastModifiedDate = Date()
        self.isArchived = false
    }
    
    func updateLastModified() {
        self.lastModifiedDate = Date()
    }
    
    var totalLogEntries: Int {
        blueprints.reduce(0) { total, blueprint in
            total + blueprint.logEntries.count
        }
    }
    
    var recentLogEntries: [LogEntry] {
        let allEntries = blueprints.flatMap { $0.logEntries }
        return Array(allEntries.sorted { $0.date > $1.date }.prefix(10))
    }
    
    // MARK: - Media Properties
    
    /// Total number of media items (photos + videos) across all blueprints
    var totalMediaItems: Int {
        blueprints.reduce(0) { total, blueprint in
            total + blueprint.totalMediaItems
        }
    }
    
    /// Total number of photos across all blueprints
    var totalPhotos: Int {
        blueprints.reduce(0) { total, blueprint in
            total + blueprint.totalPhotos
        }
    }
    
    /// Total number of videos across all blueprints
    var totalVideos: Int {
        blueprints.reduce(0) { total, blueprint in
            total + blueprint.totalVideos
        }
    }
    
    /// All log entries with media, sorted by date
    var logEntriesWithMedia: [LogEntry] {
        let allEntries = blueprints.flatMap { $0.logEntriesWithMedia }
        return allEntries.sorted { $0.date > $1.date }
    }
    
    /// Media count breakdown by category
    var mediaByCategory: [LogCategory: Int] {
        var breakdown: [LogCategory: Int] = [:]
        
        for blueprint in blueprints {
            for (category, count) in blueprint.mediaByCategory {
                breakdown[category, default: 0] += count
            }
        }
        
        return breakdown
    }
}