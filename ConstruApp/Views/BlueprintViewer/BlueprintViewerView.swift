//
//  BlueprintViewerView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import PDFKit

// Global coordinate storage that survives view reconstruction
class GlobalCoordinateStore {
    static let shared = GlobalCoordinateStore()
    private var storedCoordinates: CGPoint = CGPoint.zero
    
    private init() {}
    
    func store(_ point: CGPoint) {
        storedCoordinates = point
        print("DEBUG: GlobalCoordinateStore - stored coordinates: \(point)")
    }
    
    func retrieve() -> CGPoint {
        print("DEBUG: GlobalCoordinateStore - retrieving coordinates: \(storedCoordinates)")
        return storedCoordinates
    }
    
    func clear() {
        storedCoordinates = CGPoint.zero
        print("DEBUG: GlobalCoordinateStore - cleared coordinates")
    }
}

struct BlueprintViewerView: View {
    @Bindable var blueprint: Blueprint
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage: Int = 1
    @State private var zoomScale: CGFloat = 1.0
    @State private var showingPagePicker = false
    @State private var showingZoomControls = true
    @State private var selectedPin: LogEntry?
    @State private var showingAddLog = false
    @State private var tapLocation = CGPoint.zero
    @State private var pendingTapLocation: CGPoint?
    @State private var selectedCategories: Set<LogCategory> = Set(LogCategory.allCases)
    @State private var showingCategoryFilter = false
    @State private var showingCategoryOverview = false
    @State private var showingGallery = false
    
    // Spatial Search States
    @State private var isSearchMode = false
    @State private var searchArea: CGRect?
    @State private var searchCategories: Set<LogCategory> = Set(LogCategory.allCases)
    @State private var showingSearchResults = false
    
    private var zoomPercentage: Int {
        Int(zoomScale * 100)
    }
    
    /// Media counts for the current page
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
    
    /// Gallery context that switches between blueprint and spatial area based on search state
    private var galleryContext: GalleryContext {
        let context: GalleryContext
        if let area = searchArea {
            context = .spatialArea(blueprint, bounds: area, page: currentPage)
            print("🎯 DEBUG: Gallery context - SPATIAL AREA")
            print("🎯 DEBUG: - Blueprint: \(blueprint.name)")
            print("🎯 DEBUG: - Page: \(currentPage)")
            print("🎯 DEBUG: - Area bounds: \(area)")
            print("🎯 DEBUG: - Search results count: \(searchResults.count)")
        } else {
            context = .blueprint(blueprint)
            print("🎯 DEBUG: Gallery context - BLUEPRINT WIDE")
            print("🎯 DEBUG: - Blueprint: \(blueprint.name)")
        }
        return context
    }
    
    /// Current gallery media count - spatial area when in search mode, blueprint-wide otherwise
    private var currentGalleryMediaCount: Int {
        let count: Int
        if searchArea != nil {
            count = searchAreaMediaCount.total
            print("📊 DEBUG: Gallery media count - SPATIAL (search area): \(count)")
            print("📊 DEBUG: - Search area media breakdown: photos=\(searchAreaMediaCount.photos), videos=\(searchAreaMediaCount.videos)")
        } else {
            count = blueprint.totalMediaItems
            print("📊 DEBUG: Gallery media count - BLUEPRINT: \(count)")
        }
        return count
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            // UIKit-based PDF Viewer (better zoom/pan handling)
            UIKitPDFViewWrapper(
                blueprint: blueprint,
                currentPage: $currentPage,
                zoomScale: $zoomScale,
                selectedPin: $selectedPin,
                selectedCategories: selectedCategories,
                onTapForNewPin: { point, page in
                    print("DEBUG: BlueprintViewerView - === CALLBACK START ===")
                    print("DEBUG: BlueprintViewerView - onTapForNewPin callback with coordinates: \(point)")
                    print("DEBUG: BlueprintViewerView - BEFORE storage - showingAddLog: \(showingAddLog)")
                    
                    // Store in global store (survives view reconstruction)
                    GlobalCoordinateStore.shared.store(point)
                    
                    // Store coordinates in state variables with debug
                    pendingTapLocation = point
                    tapLocation = point
                    
                    print("DEBUG: BlueprintViewerView - AFTER storage - pendingTapLocation: \(String(describing: pendingTapLocation)), tapLocation: \(tapLocation)")
                    print("DEBUG: BlueprintViewerView - BEFORE showingAddLog = true")
                    
                    // Present sheet immediately
                    showingAddLog = true
                    
                    print("DEBUG: BlueprintViewerView - AFTER setting showingAddLog: \(showingAddLog)")
                    print("DEBUG: BlueprintViewerView - === CALLBACK END ===")
                },
                isSearchMode: isSearchMode,
                searchArea: searchArea,
                onSpatialAreaSelected: { area in
                    print("🔍 DEBUG: Spatial area selected: \(area)")
                    searchArea = area
                    // Exit search mode after selection
                    withAnimation(DesignSystem.Animation.standard) {
                        isSearchMode = false
                    }
                }
            )
            .clipped()
            
            // Floating Controls
            VStack {
                Spacer()
                
                HStack {
                    // Page Controls
                    pageControlsView
                    
                    Spacer()
                    
                    // Zoom Controls
                    if showingZoomControls {
                        zoomControlsView
                    }
                }
                .padding(DesignSystem.Spacing.screenPadding)
            }
            
            
            // Improved Spatial Search UI
            if isSearchMode || searchArea != nil {
                spatialSearchUI
            }
        }
        .navigationTitle(blueprint.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Log count indicator
                if !blueprint.logEntriesOnPage(currentPage).isEmpty {
                    Button(action: { }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                            Text("\(blueprint.logEntriesOnPage(currentPage).count)")
                                .font(.caption2)
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.primary.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .disabled(true)
                }
                
                // Gallery button - context-aware (spatial area vs blueprint)
                if currentGalleryMediaCount > 0 {
                    Button(action: { showingGallery = true }) {
                        ZStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            // Media count badge - shows spatial area count when in search mode
                            Circle()
                                .fill(DesignSystem.Colors.primary)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("\(currentGalleryMediaCount)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                )
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                
                // TEMPORARILY DISABLED - Category Overview Button
                // Button(action: { showingCategoryOverview = true }) {
                //     Image(systemName: "square.grid.3x3")
                //         .foregroundColor(DesignSystem.Colors.primary)
                // }
                
                // TEMPORARILY DISABLED - Category Filter Button  
                // Button(action: { showingCategoryFilter = true }) {
                //     ZStack {
                //         Image(systemName: "line.3.horizontal.decrease.circle")
                //             .foregroundColor(DesignSystem.Colors.primary)
                //         
                //         if selectedCategories.count < LogCategory.allCases.count {
                //             Circle()
                //                 .fill(DesignSystem.Colors.primary)
                //                 .frame(width: 8, height: 8)
                //                 .offset(x: 8, y: -8)
                //         }
                //     }
                // }
                
                // Improved Spatial Search Button
                Button(action: { toggleSearchMode() }) {
                    HStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSearchMode ? DesignSystem.Colors.primary : DesignSystem.Colors.cardBackground)
                                .frame(width: 32, height: 24)
                            
                            Image(systemName: "viewfinder")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isSearchMode ? .white : DesignSystem.Colors.primary)
                            
                            // Active area indicator
                            if searchArea != nil {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 12, y: -8)
                            }
                        }
                        
                        if isSearchMode {
                            Text("Select")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        } else if searchArea != nil {
                            Text("Area")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                
                Button(action: { showingZoomControls.toggle() }) {
                    Image(systemName: showingZoomControls ? "eye.slash" : "eye")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Menu {
                    Button(action: fitToWidth) {
                        Label("Fit to Width", systemImage: "arrow.left.and.right")
                    }
                    
                    Button(action: fitToPage) {
                        Label("Fit to Page", systemImage: "arrow.up.left.and.down.right.magnifyingglass")
                    }
                    
                    Button(action: actualSize) {
                        Label("Actual Size", systemImage: "1.magnifyingglass")
                    }
                    
                    Divider()
                    
                    Button(action: { showingPagePicker = true }) {
                        Label("Go to Page", systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Divider()
                    
                    if blueprint.totalMediaItems > 0 {
                        Button(action: { showingGallery = true }) {
                            Label("nav.media_gallery".localized, systemImage: "photo.on.rectangle.angled")
                        }
                        
                        Divider()
                    }
                    
                    Button(action: { showingAddLog = true }) {
                        Label("Add Log Entry", systemImage: "plus.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .onAppear {
            currentPage = blueprint.currentPage
            updateBlueprintCurrentPage()
        }
        .onChange(of: currentPage) { _, newPage in
            blueprint.currentPage = newPage
            updateBlueprintCurrentPage()
        }
        .sheet(isPresented: $showingPagePicker) {
            PagePickerView(
                currentPage: $currentPage,
                totalPages: blueprint.pageCount
            )
        }
        .sheet(isPresented: $showingAddLog) {
            let _ = print("DEBUG: BlueprintViewerView - === SHEET PRESENTATION START ===")
            
            // Get coordinates from global store first (survives view reconstruction)
            let globalCoords = GlobalCoordinateStore.shared.retrieve()
            let stateCoords = pendingTapLocation ?? tapLocation
            let coordinates = globalCoords != CGPoint.zero ? globalCoords : stateCoords
            
            let sourceUsed = globalCoords != CGPoint.zero ? "GlobalCoordinateStore" : (pendingTapLocation != nil ? "pendingTapLocation" : "tapLocation")
            
            let _ = print("DEBUG: BlueprintViewerView - SHEET VALUES:")
            let _ = print("DEBUG: BlueprintViewerView - GlobalCoordinateStore: \(globalCoords)")
            let _ = print("DEBUG: BlueprintViewerView - pendingTapLocation: \(String(describing: pendingTapLocation)), tapLocation: \(tapLocation)")
            let _ = print("DEBUG: BlueprintViewerView - FINAL coordinates: x=\(coordinates.x), y=\(coordinates.y) (using \(sourceUsed))")
            let _ = print("DEBUG: BlueprintViewerView - === SHEET PRESENTATION END ===")
            
            AddLogEntryView(
                blueprint: blueprint,
                xCoordinate: coordinates.x,
                yCoordinate: coordinates.y,
                pageNumber: currentPage
            )
            .onDisappear {
                GlobalCoordinateStore.shared.clear()
                pendingTapLocation = nil
                print("DEBUG: BlueprintViewerView - cleared all coordinates")
            }
        }
        .sheet(item: $selectedPin) { logEntry in
            NavigationStack {
                LogEntryDetailView(logEntry: logEntry)
            }
        }
        .sheet(isPresented: $showingCategoryFilter) {
            CategoryFilterView(
                selectedCategories: $selectedCategories,
                isPresented: $showingCategoryFilter
            )
        }
        .sheet(isPresented: $showingCategoryOverview) {
            CategoryOverviewView(
                blueprint: blueprint,
                selectedCategories: $selectedCategories
            )
        }
        .sheet(isPresented: $showingGallery) {
            MediaGalleryView(
                context: galleryContext, 
                modelContext: modelContext
            )
            .onAppear {
                print("🖼️ DEBUG: MediaGalleryView appeared with context: \(galleryContext)")
                if case .spatialArea(_, let bounds, let page) = galleryContext {
                    print("🖼️ DEBUG: Spatial area gallery - bounds: \(bounds), page: \(page)")
                }
            }
        }
    }
    
    private var pageControlsView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Previous Page
            Button(action: previousPage) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(currentPage > 1 ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText.opacity(0.5))
            }
            .disabled(currentPage <= 1)
            
            // Page Indicator with media stats
            Button(action: { showingPagePicker = true }) {
                VStack(spacing: 2) {
                    Text("\(currentPage)")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    HStack(spacing: 4) {
                        Text("of \(blueprint.pageCount)")
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        // Media indicators for current page
                        let pageMediaCount = currentPageMediaCount
                        if pageMediaCount.photos > 0 || pageMediaCount.videos > 0 {
                            HStack(spacing: 2) {
                                if pageMediaCount.photos > 0 {
                                    HStack(spacing: 1) {
                                        Image(systemName: "photo")
                                            .font(.caption2)
                                        Text("\(pageMediaCount.photos)")
                                            .font(.caption2)
                                    }
                                }
                                if pageMediaCount.videos > 0 {
                                    HStack(spacing: 1) {
                                        Image(systemName: "video")
                                            .font(.caption2)
                                        Text("\(pageMediaCount.videos)")
                                            .font(.caption2)
                                    }
                                }
                            }
                            .foregroundColor(DesignSystem.Colors.primary.opacity(0.8))
                        }
                    }
                }
            }
            
            // Next Page
            Button(action: nextPage) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(currentPage < blueprint.pageCount ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText.opacity(0.5))
            }
            .disabled(currentPage >= blueprint.pageCount)
        }
        .padding(DesignSystem.Spacing.md)
        .floatingStyle()
    }
    
    private var zoomControlsView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Zoom Out
            Button(action: zoomOut) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.title3)
                    .foregroundColor(zoomScale > 0.25 ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText.opacity(0.5))
            }
            .disabled(zoomScale <= 0.25)
            
            // Zoom Percentage
            Text("\(zoomPercentage)%")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .frame(width: 45)
            
            // Zoom In
            Button(action: zoomIn) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.title3)
                    .foregroundColor(zoomScale < 4.0 ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText.opacity(0.5))
            }
            .disabled(zoomScale >= 4.0)
        }
        .padding(DesignSystem.Spacing.md)
        .floatingStyle()
    }
    
    // MARK: - Actions
    private func previousPage() {
        if currentPage > 1 {
            currentPage -= 1
        }
    }
    
    private func nextPage() {
        if currentPage < blueprint.pageCount {
            currentPage += 1
        }
    }
    
    private func zoomIn() {
        let newZoom = min(zoomScale * 1.25, 4.0)
        withAnimation(DesignSystem.Animation.quick) {
            zoomScale = newZoom
        }
    }
    
    private func zoomOut() {
        let newZoom = max(zoomScale / 1.25, 0.25)
        withAnimation(DesignSystem.Animation.quick) {
            zoomScale = newZoom
        }
    }
    
    private func fitToWidth() {
        withAnimation(DesignSystem.Animation.standard) {
            zoomScale = 1.0 // This will be adjusted by PDFView automatically
        }
    }
    
    private func fitToPage() {
        withAnimation(DesignSystem.Animation.standard) {
            zoomScale = 0.75
        }
    }
    
    private func actualSize() {
        withAnimation(DesignSystem.Animation.standard) {
            zoomScale = 1.0
        }
    }
    
    private func updateBlueprintCurrentPage() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to update blueprint current page: \(error)")
        }
    }
    
    // MARK: - Spatial Search
    
    private func toggleSearchMode() {
        withAnimation(DesignSystem.Animation.standard) {
            isSearchMode.toggle()
            print("🔍🔍 DEBUG: toggleSearchMode - isSearchMode: \(isSearchMode)")
            print("🔍🔍 DEBUG: User tapped spatial search button (viewfinder icon)")
            if !isSearchMode {
                searchArea = nil
                print("🔍🔍 DEBUG: Cleared search area - gallery will switch back to blueprint mode")
            } else {
                print("🔍🔍 DEBUG: Entered search mode - user needs to drag to select area")
                print("🔍🔍 DEBUG: NOTE: Gallery button will only show spatial counts AFTER area is selected")
            }
        }
    }
    
    private var searchResults: [LogEntry] {
        guard let area = searchArea else { return [] }
        
        return blueprint.logEntriesOnPage(currentPage).filter { entry in
            // Check if entry is in selected categories
            guard searchCategories.contains(entry.category) else { return false }
            
            // Check if entry location is within search area
            let entryPoint = CGPoint(x: entry.xCoordinate, y: entry.yCoordinate)
            return area.contains(entryPoint)
        }
    }
    
    /// Media items within the current search area
    private var searchAreaMediaItems: [LogEntry] {
        return searchResults.filter { $0.hasMedia }
    }
    
    /// Media counts for the current search area
    private var searchAreaMediaCount: (total: Int, photos: Int, videos: Int) {
        let mediaEntries = searchAreaMediaItems
        let photos = mediaEntries.reduce(0) { total, entry in
            total + entry.photos.count
        }
        let videos = mediaEntries.reduce(0) { total, entry in
            total + (entry.videoData != nil ? 1 : 0)
        }
        return (photos + videos, photos, videos)
    }
    
    // MARK: - Redesigned Spatial Search UI
    private var spatialSearchUI: some View {
        ZStack {
            // Full-screen semi-transparent background when in search mode
            if isSearchMode {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.2), value: isSearchMode)
            }
            
            VStack {
                // Top instruction banner
                if isSearchMode && searchArea == nil {
                    searchModeInstructions
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                Spacer()
                
                // Bottom results panel
                if searchArea != nil {
                    searchResultsPanel
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
        }
    }
    
    private var searchModeInstructions: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "hand.draw")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Select Area")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Drag to select an area on the blueprint")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(DesignSystem.Animation.standard) {
                        isSearchMode = false
                        searchArea = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .font(.title3)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var searchResultsPanel: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Header with results summary
            HStack {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "viewfinder.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Selected Area")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        HStack(spacing: 8) {
                            Text("\(searchResults.count) entries")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            let mediaCount = searchAreaMediaCount
                            if mediaCount.total > 0 {
                                Text("•")
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                HStack(spacing: 6) {
                                    if mediaCount.photos > 0 {
                                        HStack(spacing: 2) {
                                            Image(systemName: "photo.fill")
                                                .font(.caption2)
                                            Text("\(mediaCount.photos)")
                                                .font(DesignSystem.Typography.caption2)
                                        }
                                        .foregroundColor(DesignSystem.Colors.primary)
                                    }
                                    
                                    if mediaCount.videos > 0 {
                                        HStack(spacing: 2) {
                                            Image(systemName: "video.fill")
                                                .font(.caption2)
                                            Text("\(mediaCount.videos)")
                                                .font(DesignSystem.Typography.caption2)
                                        }
                                        .foregroundColor(DesignSystem.Colors.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // View Gallery Button
                    if searchAreaMediaCount.total > 0 {
                        Button(action: { showingGallery = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.caption)
                                Text("Gallery")
                                    .font(DesignSystem.Typography.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(16)
                        }
                    }
                    
                    // Clear Selection Button
                    Button(action: { 
                        withAnimation(DesignSystem.Animation.standard) {
                            searchArea = nil
                            isSearchMode = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .font(.title3)
                    }
                }
            }
            
            // Results grid (if there are results)
            if !searchResults.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 70, maximum: 90), spacing: DesignSystem.Spacing.sm)
                ], spacing: DesignSystem.Spacing.sm) {
                    ForEach(searchResults.prefix(6)) { entry in // Show max 6 results in preview
                        searchResultCard(for: entry)
                    }
                    
                    if searchResults.count > 6 {
                        VStack {
                            Text("+\(searchResults.count - 6)")
                                .font(DesignSystem.Typography.captionMedium)
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Text("more")
                                .font(DesignSystem.Typography.caption2)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .frame(width: 70, height: 70)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .onTapGesture {
                            // Show all results in a sheet or expand
                            showingSearchResults = true
                        }
                    }
                }
                .frame(height: 80)
            } else {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("No entries found in selected area")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(.ultraThinMaterial)
        .cornerRadius(DesignSystem.CornerRadius.large)
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
    }
    
    private func searchResultCard(for entry: LogEntry) -> some View {
        ZStack {
            VStack(spacing: 2) {
                // Category Icon
                Image(systemName: entry.category.iconName)
                    .foregroundColor(entry.category.color)
                    .font(.title3)
                
                // Entry Title
                Text(entry.title)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70, height: 70)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            // Media indicator badge
            if entry.hasMedia {
                VStack {
                    HStack {
                        Spacer()
                        
                        Circle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 16, height: 16)
                            .overlay(
                                HStack(spacing: 0) {
                                    if !entry.photos.isEmpty {
                                        Image(systemName: "photo.fill")
                                            .font(.system(size: 6))
                                    }
                                    if entry.hasVideo {
                                        Image(systemName: "video.fill")
                                            .font(.system(size: 6))
                                    }
                                }
                                .foregroundColor(.white)
                            )
                            .padding(.trailing, 6)
                            .padding(.top, 6)
                    }
                    Spacer()
                }
            }
        }
        .onTapGesture {
            selectedPin = entry
        }
    }
}

struct PagePickerView: View {
    @Binding var currentPage: Int
    let totalPages: Int
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage: Int
    
    init(currentPage: Binding<Int>, totalPages: Int) {
        self._currentPage = currentPage
        self.totalPages = totalPages
        self._selectedPage = State(initialValue: currentPage.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Go to Page")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("Page \(selectedPage) of \(totalPages)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Picker("Page", selection: $selectedPage) {
                    ForEach(1...totalPages, id: \.self) { page in
                        Text("Page \(page)")
                            .tag(page)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.screenPadding)
            .navigationTitle("Select Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Go") {
                        currentPage = selectedPage
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    // Create sample data for preview
    let sampleData = Data()
    let blueprint = Blueprint(
        name: "Sample Blueprint",
        fileName: "sample.pdf",
        pdfData: sampleData,
        pageCount: 5,
        pdfWidth: 612,
        pdfHeight: 792
    )
    
    return NavigationStack {
        BlueprintViewerView(blueprint: blueprint)
    }
    .modelContainer(for: [Project.self, Blueprint.self, LogEntry.self], inMemory: true)
}