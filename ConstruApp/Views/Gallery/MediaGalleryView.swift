//
//  MediaGalleryView.swift
//  ConstruApp
//
//  Created by Claude on 8/11/25.
//

import SwiftUI
import SwiftData

struct MediaGalleryView: View {
    let context: GalleryContext
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var dataProvider: GalleryDataProvider
    @State private var filter = GalleryFilter.all
    @State private var selectedMediaItem: GalleryMediaItem?
    @State private var showingMediaDetail = false
    @State private var showingFilters = false
    @State private var showingDatePicker = false
    @State private var showingCategoryFilter = false
    
    init(context: GalleryContext, modelContext: ModelContext) {
        self.context = context
        self._dataProvider = State(initialValue: GalleryDataProvider(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content area with clean, minimal design
                VStack(spacing: 0) {
                    // Elegant header with context info
                    galleryHeader
                    
                    // Content area
                    if dataProvider.isLoading {
                        loadingView
                    } else if dataProvider.mediaItems.isEmpty {
                        emptyStateView
                    } else {
                        galleryGrid
                    }
                }
                
                // Floating filter controls - architect-inspired design
                VStack {
                    HStack {
                        Spacer()
                        filterControlPanel
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("general.close".localized)
                                .font(DesignSystem.Typography.bodyMedium)
                        }
                        .foregroundColor(themeManager.adaptiveColor(.primary))
                    }
                }
            }
            .onAppear {
                loadMedia()
            }
            .sheet(isPresented: $showingMediaDetail) {
                if let selectedItem = selectedMediaItem {
                    MediaDetailView(
                        mediaItem: selectedItem,
                        allMediaItems: dataProvider.mediaItems
                    )
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DateRangePickerView(
                    startDate: Binding(
                        get: { filter.dateRange?.start ?? Date().addingTimeInterval(-30*24*60*60) },
                        set: { newStart in
                            let end = filter.dateRange?.end ?? Date()
                            filter.dateRange = DateInterval(start: newStart, end: end)
                        }
                    ),
                    endDate: Binding(
                        get: { filter.dateRange?.end ?? Date() },
                        set: { newEnd in
                            let start = filter.dateRange?.start ?? Date().addingTimeInterval(-30*24*60*60)
                            filter.dateRange = DateInterval(start: start, end: newEnd)
                        }
                    )
                )
                .environmentObject(themeManager)
                .onDisappear {
                    loadMedia()
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingCategoryFilter) {
                GalleryCategoryFilterView(
                    selectedCategories: $filter.categories,
                    onSelectionChange: loadMedia
                )
                .environmentObject(themeManager)
                .presentationDetents([.medium])
            }
        }
    }
    
    private var galleryGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: DesignSystem.Spacing.lg) {
                ForEach(dataProvider.mediaItems) { mediaItem in
                    MediaGalleryItem(mediaItem: mediaItem) {
                        selectedMediaItem = mediaItem
                        showingMediaDetail = true
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
                    .shadow(
                        color: themeManager.adaptiveColor(.primaryText).opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
            }
            .padding(DesignSystem.Spacing.screenPadding)
            // Add extra bottom padding to account for floating controls
            .padding(.bottom, 100)
        }
        .background(themeManager.adaptiveColor(.background))
    }
    
    private var gridColumns: [GridItem] {
        [
            // More architectural proportions - golden ratio inspired
            GridItem(.adaptive(minimum: 140, maximum: 240), spacing: DesignSystem.Spacing.lg)
        ]
    }
    
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("gallery.loading_media".localized)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(themeManager.adaptiveColor(.secondaryText))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.adaptiveColor(.background))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(themeManager.adaptiveColor(.secondaryText))
            
            Text("gallery.no_media_title".localized)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(themeManager.adaptiveColor(.primaryText))
            
            Text("gallery.no_media_subtitle".localized)
                .font(DesignSystem.Typography.body)
                .foregroundColor(themeManager.adaptiveColor(.secondaryText))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.adaptiveColor(.background))
    }
    
    private var statisticsButton: some View {
        Menu {
            let stats = dataProvider.mediaStatistics
            
            Text("gallery.total_items".localized(args: stats.totalItems))
            Text("gallery.photos_count".localized(args: stats.photoCount))
            Text("gallery.videos_count".localized(args: stats.videoCount))
            
            Divider()
            
            ForEach(Array(stats.categoryBreakdown.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { category in
                let count = stats.categoryBreakdown[category] ?? 0
                if count > 0 {
                    Label("\(category.displayName): \(count)", systemImage: category.iconName)
                }
            }
        } label: {
            Image(systemName: "chart.bar")
                .foregroundColor(themeManager.adaptiveColor(.primary))
        }
    }
    
    // MARK: - Elegant Header Design
    private var galleryHeader: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Context title with elegant typography
                    Text(context.title)
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(themeManager.adaptiveColor(.primaryText))
                    
                    // Subtle stats with architectural precision
                    HStack(spacing: DesignSystem.Spacing.md) {
                        let stats = dataProvider.mediaStatistics
                        
                        if stats.totalItems > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.caption)
                                Text("\(stats.totalItems)")
                                    .font(DesignSystem.Typography.captionMedium)
                            }
                            .foregroundColor(themeManager.adaptiveColor(.secondaryText))
                            
                            if stats.photoCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo")
                                        .font(.caption)
                                    Text("\(stats.photoCount)")
                                        .font(DesignSystem.Typography.captionMedium)
                                }
                                .foregroundColor(themeManager.adaptiveColor(.secondaryText))
                            }
                            
                            if stats.videoCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "video")
                                        .font(.caption)
                                    Text("\(stats.videoCount)")
                                        .font(DesignSystem.Typography.captionMedium)
                                }
                                .foregroundColor(themeManager.adaptiveColor(.secondaryText))
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Active filter indicators - minimal and elegant
                if hasActiveFilters {
                    activeFilterIndicators
                }
            }
            
            // Thin separator line - architectural detail
            Rectangle()
                .fill(themeManager.adaptiveColor(.secondaryText).opacity(0.2))
                .frame(height: 1)
        }
        .padding(DesignSystem.Spacing.screenPadding)
        .background(themeManager.adaptiveColor(.background))
    }
    
    // MARK: - Floating Filter Control Panel
    private var filterControlPanel: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Primary filter button with subtle elevation
            Button(action: { 
                withAnimation(DesignSystem.Animation.standard) {
                    showingFilters.toggle()
                }
            }) {
                Image(systemName: showingFilters ? "slider.horizontal.3" : "slider.horizontal.3")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(themeManager.adaptiveColor(.primaryText))
                    .frame(width: 48, height: 48)
                    .background(themeManager.adaptiveColor(.cardBackground))
                    .clipShape(Circle())
                    .shadow(color: themeManager.adaptiveColor(.primaryText).opacity(0.1), radius: 8, x: 0, y: 4)
            }
            
            // Expanded filter options - appears with elegant animation
            if showingFilters {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    // Date filter
                    filterActionButton(
                        icon: "calendar",
                        isActive: filter.dateRange != nil,
                        action: { showingDatePicker = true }
                    )
                    
                    // Category filter
                    filterActionButton(
                        icon: "tag",
                        isActive: filter.categories.count < LogCategory.allCases.count,
                        action: { showingCategoryFilter = true }
                    )
                    
                    // Media type filters
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        mediaTypeToggle(icon: "photo", isActive: filter.showPhotos) {
                            filter.showPhotos.toggle()
                            loadMedia()
                        }
                        mediaTypeToggle(icon: "video", isActive: filter.showVideos) {
                            filter.showVideos.toggle()
                            loadMedia()
                        }
                    }
                    
                    // Clear all filters
                    if hasActiveFilters {
                        Button(action: clearAllFilters) {
                            Text("general.clear".localized)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(themeManager.adaptiveColor(.error))
                        }
                        .padding(.top, DesignSystem.Spacing.xs)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Helper Views
    private func filterActionButton(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isActive ? themeManager.adaptiveColor(.buttonText) : themeManager.adaptiveColor(.primaryText))
                .frame(width: 36, height: 36)
                .background(isActive ? themeManager.adaptiveColor(.primary) : themeManager.adaptiveColor(.cardBackground))
                .clipShape(Circle())
                .shadow(color: themeManager.adaptiveColor(.primaryText).opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }
    
    private func mediaTypeToggle(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isActive ? themeManager.adaptiveColor(.buttonText) : themeManager.adaptiveColor(.secondaryText))
                .frame(width: 28, height: 28)
                .background(isActive ? themeManager.adaptiveColor(.primary) : themeManager.adaptiveColor(.secondaryBackground))
                .clipShape(Circle())
        }
    }
    
    private var activeFilterIndicators: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            if filter.dateRange != nil {
                filterPill("calendar", color: themeManager.adaptiveColor(.primary))
            }
            if filter.categories.count < LogCategory.allCases.count {
                filterPill("tag", color: themeManager.adaptiveColor(.secondary))
            }
            if !filter.showPhotos || !filter.showVideos {
                filterPill("photo.on.rectangle", color: themeManager.adaptiveColor(.tertiary))
            }
        }
    }
    
    private func filterPill(_ icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 20, height: 20)
            .background(color)
            .clipShape(Circle())
    }
    
    private var hasActiveFilters: Bool {
        filter.dateRange != nil ||
        filter.categories.count < LogCategory.allCases.count ||
        !filter.showPhotos ||
        !filter.showVideos
    }
    
    private func clearAllFilters() {
        withAnimation(DesignSystem.Animation.standard) {
            filter = .all
            loadMedia()
        }
    }
    
    private func loadMedia() {
        dataProvider.loadMedia(for: context, filter: filter)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        var body: some View {
            let container = try! ModelContainer(for: Project.self, Blueprint.self, LogEntry.self)
            let context = container.mainContext
            
            // Create sample data
            let project = Project(name: "Sample Project", description: "A sample project")
            context.insert(project)
            
            let blueprint = Blueprint(name: "Sample Blueprint", fileName: "sample.pdf", pdfData: Data(), pageCount: 1, pdfWidth: 612, pdfHeight: 792)
            blueprint.project = project
            context.insert(blueprint)
            
            let logEntry = LogEntry(
                title: "Sample Entry",
                notes: "Sample notes",
                category: .electrical,
                xCoordinate: 0.5,
                yCoordinate: 0.5,
                pageNumber: 1
            )
            logEntry.blueprint = blueprint
            context.insert(logEntry)
            
            return MediaGalleryView(
                context: .project(project),
                modelContext: context
            )
            .environmentObject(ThemeManager.shared)
        }
    }
    
    return PreviewContainer()
}