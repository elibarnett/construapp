//
//  MediaDetailView.swift
//  ConstruApp
//
//  Created by Claude on 8/11/25.
//

import SwiftUI
import AVKit

struct MediaDetailView: View {
    let mediaItem: GalleryMediaItem
    let allMediaItems: [GalleryMediaItem]
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var currentIndex: Int
    @State private var showingControls = true
    @State private var showingInfoPanel = false
    @State private var hideControlsTask: Task<Void, Never>?
    
    init(mediaItem: GalleryMediaItem, allMediaItems: [GalleryMediaItem]) {
        self.mediaItem = mediaItem
        self.allMediaItems = allMediaItems
        self._currentIndex = State(initialValue: allMediaItems.firstIndex { $0.id == mediaItem.id } ?? 0)
    }
    
    private var currentMediaItem: GalleryMediaItem {
        guard currentIndex >= 0 && currentIndex < allMediaItems.count else {
            return mediaItem
        }
        return allMediaItems[currentIndex]
    }
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Media content
            mediaContent
                .gesture(
                    TapGesture()
                        .onEnded { _ in
                            toggleControls()
                        }
                )
            
            // Controls overlay
            if showingControls {
                controlsOverlay
                    .transition(.opacity)
            }
            
            // Info panel
            if showingInfoPanel {
                infoPanel
                    .transition(.move(edge: .bottom))
            }
        }
        .statusBarHidden(!showingControls)
        .onAppear {
            startHideControlsTimer()
        }
    }
    
    @ViewBuilder
    private var mediaContent: some View {
        GeometryReader { geometry in
            switch currentMediaItem.mediaType {
            case .photo:
                photoView(geometry: geometry)
            case .video:
                videoView
            }
        }
    }
    
    private func photoView(geometry: GeometryProxy) -> some View {
        Group {
            if let image = UIImage(data: currentMediaItem.mediaData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .gesture(
                        MagnificationGesture()
                            .simultaneously(with: DragGesture())
                    )
            } else {
                Text("gallery.image_load_error".localized)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var videoView: some View {
        Group {
            if let videoURL = createTemporaryVideoURL() {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        // Auto-cleanup after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            try? FileManager.default.removeItem(at: videoURL)
                        }
                    }
            } else {
                Text("gallery.video_load_error".localized)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private var controlsOverlay: some View {
        VStack {
            // Top controls
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button(action: { showingInfoPanel.toggle() }) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            // Bottom controls
            HStack {
                // Previous button
                Button(action: previousMedia) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(canGoPrevious ? .white : .gray)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .disabled(!canGoPrevious)
                
                Spacer()
                
                // Media counter
                Text("\(currentIndex + 1) / \(allMediaItems.count)")
                    .foregroundColor(.white)
                    .font(DesignSystem.Typography.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                
                Spacer()
                
                // Next button
                Button(action: nextMedia) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(canGoNext ? .white : .gray)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .disabled(!canGoNext)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("gallery.media_info".localized)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(themeManager.adaptiveColor(.primaryText))
                
                Spacer()
                
                Button(action: { showingInfoPanel = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(themeManager.adaptiveColor(.secondaryText))
                }
            }
            
            // Media details
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                InfoRow(
                    label: "log.title".localized,
                    value: currentMediaItem.title
                )
                
                InfoRow(
                    label: "general.category".localized,
                    value: currentMediaItem.category.displayName,
                    color: categoryColor
                )
                
                InfoRow(
                    label: "nav.blueprint".localized,
                    value: currentMediaItem.blueprintName
                )
                
                InfoRow(
                    label: "general.date".localized,
                    value: formatDate(currentMediaItem.date)
                )
                
                if let fileName = currentMediaItem.fileName {
                    InfoRow(
                        label: "general.filename".localized,
                        value: fileName
                    )
                }
                
                InfoRow(
                    label: "general.type".localized,
                    value: currentMediaItem.mediaType == .photo ? "general.photo".localized : "general.video".localized
                )
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .background(themeManager.adaptiveColor(.cardBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 300, alignment: .bottom)
    }
    
    private var canGoPrevious: Bool {
        currentIndex > 0
    }
    
    private var canGoNext: Bool {
        currentIndex < allMediaItems.count - 1
    }
    
    private var categoryColor: Color {
        switch currentMediaItem.category {
        case .electrical: return themeManager.adaptiveColor(.electrical)
        case .plumbing: return themeManager.adaptiveColor(.plumbing)
        case .structural: return themeManager.adaptiveColor(.structural)
        case .hvac: return themeManager.adaptiveColor(.hvac)
        case .insulation: return themeManager.adaptiveColor(.insulation)
        case .flooring: return themeManager.adaptiveColor(.flooring)
        case .roofing: return themeManager.adaptiveColor(.roofing)
        case .windows: return themeManager.adaptiveColor(.windows)
        case .doors: return themeManager.adaptiveColor(.doors)
        case .finishes: return themeManager.adaptiveColor(.finishes)
        case .safety: return themeManager.adaptiveColor(.safety)
        case .general: return themeManager.adaptiveColor(.general)
        }
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingControls.toggle()
        }
        
        if showingControls {
            startHideControlsTimer()
        }
    }
    
    private func startHideControlsTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingControls = false
                    }
                }
            }
        }
    }
    
    private func previousMedia() {
        guard canGoPrevious else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex -= 1
        }
        startHideControlsTimer()
    }
    
    private func nextMedia() {
        guard canGoNext else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            currentIndex += 1
        }
        startHideControlsTimer()
    }
    
    private func createTemporaryVideoURL() -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        do {
            try currentMediaItem.mediaData.write(to: tempURL)
            return tempURL
        } catch {
            print("Error creating temporary video file: \(error)")
            return nil
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    let color: Color?
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    init(label: String, value: String, color: Color? = nil) {
        self.label = label
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(themeManager.adaptiveColor(.secondaryText))
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(color ?? themeManager.adaptiveColor(.primaryText))
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
    
    MediaDetailView(
        mediaItem: sampleMediaItem,
        allMediaItems: [sampleMediaItem]
    )
    .environmentObject(ThemeManager.shared)
}