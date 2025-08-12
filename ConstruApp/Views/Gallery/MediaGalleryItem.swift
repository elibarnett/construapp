//
//  MediaGalleryItem.swift
//  ConstruApp
//
//  Created by Claude on 8/11/25.
//

import SwiftUI
import AVKit

struct MediaGalleryItem: View {
    let mediaItem: GalleryMediaItem
    let onTap: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let itemSize: CGFloat = 120
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Media content
                mediaContent
                
                // Media type indicator
                mediaTypeIndicator
                
                // Category indicator
                categoryIndicator
            }
        }
        .buttonStyle(PlainButtonStyle())
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .shadow(
            color: themeManager.adaptiveColor(.cardShadow),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    @ViewBuilder
    private var mediaContent: some View {
        switch mediaItem.mediaType {
        case .photo:
            photoContent
        case .video:
            videoContent
        }
    }
    
    private var photoContent: some View {
        Group {
            if let image = UIImage(data: mediaItem.mediaData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: itemSize, height: itemSize)
                    .clipped()
            } else {
                photoPlaceholder
            }
        }
    }
    
    private var videoContent: some View {
        ZStack {
            // Video thumbnail
            if let thumbnail = generateVideoThumbnail(from: mediaItem.mediaData) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: itemSize, height: itemSize)
                    .clipped()
            } else {
                videoPlaceholder
            }
            
            // Play button overlay
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .offset(x: 1) // Slight offset for visual centering
                )
        }
    }
    
    private var photoPlaceholder: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
            .fill(themeManager.adaptiveColor(.secondaryBackground))
            .frame(width: itemSize, height: itemSize)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.adaptiveColor(.secondaryText))
            )
    }
    
    private var videoPlaceholder: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
            .fill(themeManager.adaptiveColor(.secondaryBackground))
            .frame(width: itemSize, height: itemSize)
            .overlay(
                Image(systemName: "video")
                    .font(.system(size: 24))
                    .foregroundColor(themeManager.adaptiveColor(.secondaryText))
            )
    }
    
    private var mediaTypeIndicator: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Image(systemName: mediaItem.mediaType == .photo ? "camera.fill" : "video.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(.trailing, 6)
                    .padding(.bottom, 6)
            }
        }
    }
    
    private var categoryIndicator: some View {
        VStack {
            HStack {
                Circle()
                    .fill(themeManager.adaptiveColor(categoryColor))
                    .frame(width: 12, height: 12)
                    .padding(.leading, 6)
                    .padding(.top, 6)
                
                Spacer()
            }
            Spacer()
        }
    }
    
    private var categoryColor: ThemeManager.ColorType {
        switch mediaItem.category {
        case .electrical: return .electrical
        case .plumbing: return .plumbing
        case .structural: return .structural
        case .hvac: return .hvac
        case .insulation: return .insulation
        case .flooring: return .flooring
        case .roofing: return .roofing
        case .windows: return .windows
        case .doors: return .doors
        case .finishes: return .finishes
        case .safety: return .safety
        case .general: return .general
        }
    }
    
    /// Generates a thumbnail from video data
    private func generateVideoThumbnail(from videoData: Data) -> UIImage? {
        // Create temporary file for video data
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        do {
            try videoData.write(to: tempURL)
            
            let asset = AVURLAsset(url: tempURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: itemSize * 2, height: itemSize * 2)
            
            let time = CMTime(seconds: 1, preferredTimescale: 60)
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)
            
            return UIImage(cgImage: cgImage)
        } catch {
            // Clean up temporary file on error
            try? FileManager.default.removeItem(at: tempURL)
            return nil
        }
    }
}

#Preview {
    let sampleLogEntry = LogEntry(
        title: "Sample Entry",
        notes: "Sample notes",
        category: .electrical,
        xCoordinate: 0.5,
        yCoordinate: 0.5,
        pageNumber: 1
    )
    
    let sampleMediaItem = GalleryMediaItem(
        logEntry: sampleLogEntry,
        mediaData: Data(),
        mediaType: .photo,
        fileName: "sample.jpg"
    )
    
    MediaGalleryItem(mediaItem: sampleMediaItem) {
        print("Tapped media item")
    }
    .environmentObject(ThemeManager.shared)
    .padding()
}