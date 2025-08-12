//
//  LogEntry.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import Foundation
import SwiftData

@Model
final class LogEntry {
    var id: UUID
    var title: String
    var notes: String
    var date: Date
    var category: LogCategory
    
    // Blueprint coordinates (normalized 0-1)
    var xCoordinate: Double
    var yCoordinate: Double
    var pageNumber: Int
    
    // Media attachments
    var photos: [Data] = []
    var videoData: Data?
    var videoFileName: String?
    
    // Relationships
    var blueprint: Blueprint?
    
    init(
        title: String,
        notes: String = "",
        date: Date = Date(),
        category: LogCategory,
        xCoordinate: Double,
        yCoordinate: Double,
        pageNumber: Int
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.date = date
        self.category = category
        self.xCoordinate = xCoordinate
        self.yCoordinate = yCoordinate
        self.pageNumber = pageNumber
    }
    
    var hasMedia: Bool {
        return !photos.isEmpty || videoData != nil
    }
    
    var photoCount: Int {
        return photos.count
    }
    
    var hasVideo: Bool {
        return videoData != nil
    }
    
    /// Total count of media items (photos + video if present)
    var mediaCount: Int {
        return photos.count + (videoData != nil ? 1 : 0)
    }
    
    func addPhoto(_ imageData: Data) {
        photos.append(imageData)
    }
    
    func removePhoto(at index: Int) {
        guard index < photos.count else { return }
        photos.remove(at: index)
    }
    
    func setVideo(_ data: Data, fileName: String) {
        videoData = data
        videoFileName = fileName
    }
    
    func removeVideo() {
        videoData = nil
        videoFileName = nil
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - LogCategory Enum
enum LogCategory: String, CaseIterable, Codable {
    case electrical = "electrical"
    case plumbing = "plumbing"
    case structural = "structural"
    case hvac = "hvac"
    case insulation = "insulation"
    case flooring = "flooring"
    case roofing = "roofing"
    case windows = "windows"
    case doors = "doors"
    case finishes = "finishes"
    case safety = "safety"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .electrical:
            return "category.electrical".localized
        case .plumbing:
            return "category.plumbing".localized
        case .structural:
            return "category.structural".localized
        case .hvac:
            return "category.hvac".localized
        case .insulation:
            return "category.insulation".localized
        case .flooring:
            return "category.flooring".localized
        case .roofing:
            return "category.roofing".localized
        case .windows:
            return "category.windows".localized
        case .doors:
            return "category.doors".localized
        case .finishes:
            return "category.finishes".localized
        case .safety:
            return "category.safety".localized
        case .general:
            return "category.general".localized
        }
    }
    
    var iconName: String {
        switch self {
        case .electrical:
            return "bolt.fill"
        case .plumbing:
            return "drop.fill"
        case .structural:
            return "building.2.fill"
        case .hvac:
            return "wind"
        case .insulation:
            return "thermometer.medium"
        case .flooring:
            return "square.grid.3x3.fill"
        case .roofing:
            return "house.fill"
        case .windows:
            return "rectangle.portrait.fill"
        case .doors:
            return "door.left.hand.open"
        case .finishes:
            return "paintbrush.fill"
        case .safety:
            return "exclamationmark.triangle.fill"
        case .general:
            return "note.text"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .electrical:
            return "category.electrical.desc".localized
        case .plumbing:
            return "category.plumbing.desc".localized
        case .structural:
            return "category.structural.desc".localized
        case .hvac:
            return "category.hvac.desc".localized
        case .insulation:
            return "category.insulation.desc".localized
        case .flooring:
            return "category.flooring.desc".localized
        case .roofing:
            return "category.roofing.desc".localized
        case .windows:
            return "category.windows.desc".localized
        case .doors:
            return "category.doors.desc".localized
        case .finishes:
            return "category.finishes.desc".localized
        case .safety:
            return "category.safety.desc".localized
        case .general:
            return "category.general.desc".localized
        }
    }
    
    static var constructionCategories: [LogCategory] {
        return [.structural, .electrical, .plumbing, .hvac, .insulation, .roofing]
    }
    
    static var finishingCategories: [LogCategory] {
        return [.flooring, .windows, .doors, .finishes]
    }
    
    static var otherCategories: [LogCategory] {
        return [.safety, .general]
    }
}