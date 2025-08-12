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
                    
                    // Filter bar
                    filterBar

                    // Content area
                    if dataProvider.isLoading {
                        loadingView
                    } else if dataProvider.mediaItems.isEmpty {
                        emptyStateView
                    } else {
                        galleryGrid
                    }
                }
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
            LazyVGrid(columns: gridColumns, spacing: DesignSystem.Spacing.sm) {
                ForEach(dataProvider.mediaItems) { mediaItem in
                    MediaGalleryItem(mediaItem: mediaItem) {
                        selectedMediaItem = mediaItem
                        showingMediaDetail = true
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                    .shadow(
                        color: themeManager.adaptiveColor(.primaryText).opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                }
            }
            .padding(DesignSystem.Spacing.screenPadding)
        }
        .background(themeManager.adaptiveColor(.background))
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 100, maximum: 180), spacing: DesignSystem.Spacing.sm)
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
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Filter buttons
                Button(action: { showingDatePicker = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text("Date")
                    }
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(themeManager.adaptiveColor(.primaryText))
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }

                Button(action: { showingCategoryFilter = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "tag")
                        Text("Category")
                    }
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(themeManager.adaptiveColor(.primaryText))
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }

                Spacer()

                // Media type toggles
                mediaTypeToggle(icon: "photo.fill", isActive: $filter.showPhotos)
                mediaTypeToggle(icon: "video.fill", isActive: $filter.showVideos)

                if hasActiveFilters {
                    Button(action: clearAllFilters) {
                        Text("Clear All")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(themeManager.adaptiveColor(.error))
                    }
                    .padding(.leading, DesignSystem.Spacing.sm)
                }
            }
            
            activeFiltersView
        }
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(themeManager.adaptiveColor(.background))
    }

    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if let dateRange = filter.dateRange {
                    let dateString = dateFilterTitle(from: dateRange)
                    FilterChipView(title: "🗓️ \(dateString)") {
                        filter.dateRange = nil
                        loadMedia()
                    }
                }

                let selectedCategories = filter.categories.sorted(by: { $0.displayName < $1.displayName })

                if selectedCategories.count < LogCategory.allCases.count {
                    ForEach(selectedCategories, id: \.self) { category in
                        FilterChipView(title: category.displayName) {
                            filter.categories.remove(category)
                            loadMedia()
                        }
                    }
                }
            }
        }
    }
    
    private func dateFilterTitle(from dateRange: DateInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if Calendar.current.isDate(dateRange.start, inSameDayAs: dateRange.end) {
            return formatter.string(from: dateRange.start)
        } else {
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        }
    }
    
    private func mediaTypeToggle(icon: String, isActive: Binding<Bool>) -> some View {
        Button(action: {
            isActive.wrappedValue.toggle()
            loadMedia()
        }) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isActive.wrappedValue ? themeManager.adaptiveColor(.primary) : themeManager.adaptiveColor(.secondaryText))
        }
        .buttonStyle(PlainButtonStyle())
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


// MARK: - FilterChipView
struct FilterChipView: View {
    let title: String
    let onRemove: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(themeManager.adaptiveColor(.primaryText))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.adaptiveColor(.secondaryText))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(themeManager.adaptiveColor(.secondaryBackground))
        .cornerRadius(12)
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