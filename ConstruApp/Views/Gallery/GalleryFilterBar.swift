//
//  GalleryFilterBar.swift
//  ConstruApp
//
//  Created by Claude on 8/11/25.
//

import SwiftUI

struct GalleryFilterBar: View {
    @Binding var filter: GalleryFilter
    let onFilterChange: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingDatePicker = false
    @State private var showingCategoryFilter = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Date filter - MOVED TO FRONT FOR TESTING
                dateFilterButton
                
                Divider()
                    .frame(height: 20)
                
                // Media type filters
                mediaTypeFilters
                
                Divider()
                    .frame(height: 20)
                
                // Category filter
                categoryFilterButton
                    .onAppear {
                        print("🗓️ DEBUG: Date filter button appeared - dateRange: \(filter.dateRange?.description ?? "nil")")
                        print("🗓️ DEBUG: Date filter title: '\(dateFilterTitle)'")
                        print("🗓️ DEBUG: Date filter isSelected: \(filter.dateRange != nil)")
                    }
                
                // Clear filters button
                if !isDefaultFilter {
                    clearFiltersButton
                        .onAppear {
                            print("🧹 DEBUG: Clear filter button appeared")
                        }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .background(themeManager.adaptiveColor(.cardBackground))
        .onAppear {
            print("📊 DEBUG: GalleryFilterBar appeared with filter: \(filter)")
            print("📊 DEBUG: Filter dateRange: \(filter.dateRange?.description ?? "nil")")
            print("📊 DEBUG: Filter categories: \(filter.categories.count) of \(LogCategory.allCases.count)")
            print("📊 DEBUG: isDefaultFilter: \(isDefaultFilter)")
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
                .onAppear {
                    print("📅📅 DEBUG: Date picker sheet APPEARED successfully!")
                    print("📅📅 DEBUG: User should now see date range picker")
                }
                .onDisappear {
                    print("📅📅 DEBUG: Date picker sheet DISAPPEARED")
                }
        }
        .onChange(of: showingDatePicker) { _, newValue in
            print("📅📅 DEBUG: showingDatePicker state changed to: \(newValue)")
            if newValue {
                print("📅📅 DEBUG: Sheet should be presenting now...")
            } else {
                print("📅📅 DEBUG: Sheet was dismissed")
            }
        }
        .sheet(isPresented: $showingCategoryFilter) {
            categoryFilterSheet
        }
    }
    
    private var mediaTypeFilters: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            FilterChip(
                title: "general.photos".localized,
                icon: "photo",
                isSelected: filter.showPhotos,
                onTap: {
                    filter.showPhotos.toggle()
                    onFilterChange()
                }
            )
            
            FilterChip(
                title: "general.videos".localized,
                icon: "video",
                isSelected: filter.showVideos,
                onTap: {
                    filter.showVideos.toggle()
                    onFilterChange()
                }
            )
        }
    }
    
    private var categoryFilterButton: some View {
        FilterChip(
            title: categoryFilterTitle,
            icon: "tag",
            isSelected: filter.categories.count < LogCategory.allCases.count,
            onTap: {
                showingCategoryFilter = true
            }
        )
    }
    
    private var dateFilterButton: some View {
        FilterChip(
            title: dateFilterTitle,
            icon: "calendar",
            isSelected: filter.dateRange != nil,
            onTap: {
                print("🗓️🗓️ DEBUG: ==== DATE FILTER BUTTON TAPPED ====")
                print("🗓️🗓️ DEBUG: Current showingDatePicker: \(showingDatePicker)")
                showingDatePicker = true
                print("🗓️🗓️ DEBUG: Set showingDatePicker to: \(showingDatePicker)")
                print("🗓️🗓️ DEBUG: Should open date picker sheet now...")
            }
        )
        .background(Color.red.opacity(0.5)) // Make red background more visible for debugging
        .border(Color.green, width: 2) // Add green border to make it super obvious
        .onAppear {
            print("🗓️ DEBUG: Date filter chip created with title: '\(dateFilterTitle)'")
        }
    }
    
    private var clearFiltersButton: some View {
        Button(action: {
            filter = .all
            onFilterChange()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                Text("general.clear".localized)
                    .font(DesignSystem.Typography.captionMedium)
            }
            .foregroundColor(themeManager.adaptiveColor(.error))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.adaptiveColor(.error).opacity(0.1))
            )
        }
    }
    
    private var categoryFilterTitle: String {
        let selectedCount = filter.categories.count
        let totalCount = LogCategory.allCases.count
        
        if selectedCount == totalCount {
            return "filter.all_categories".localized
        } else if selectedCount == 1 {
            let category = filter.categories.first!
            return category.displayName
        } else {
            return "filter.categories_count".localized(args: selectedCount)
        }
    }
    
    private var dateFilterTitle: String {
        guard let dateRange = filter.dateRange else {
            return "filter.all_dates".localized
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(dateRange.start, inSameDayAs: dateRange.end) {
            return formatter.string(from: dateRange.start)
        } else {
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        }
    }
    
    private var isDefaultFilter: Bool {
        filter.categories.count == LogCategory.allCases.count &&
        filter.dateRange == nil &&
        filter.showPhotos &&
        filter.showVideos
    }
    
    // MARK: - Sheets
    
    private var datePickerSheet: some View {
        NavigationStack {
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
            .navigationTitle("filter.select_date_range".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("general.clear".localized) {
                        filter.dateRange = nil
                        onFilterChange()
                        showingDatePicker = false
                    }
                    .foregroundColor(themeManager.adaptiveColor(.error))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("general.done".localized) {
                        onFilterChange()
                        showingDatePicker = false
                    }
                    .foregroundColor(themeManager.adaptiveColor(.primary))
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var categoryFilterSheet: some View {
        NavigationStack {
            GalleryCategoryFilterView(
                selectedCategories: $filter.categories,
                onSelectionChange: onFilterChange
            )
            .navigationTitle("filter.select_categories".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("general.done".localized) {
                        showingCategoryFilter = false
                    }
                    .foregroundColor(themeManager.adaptiveColor(.primary))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(DesignSystem.Typography.captionMedium)
            }
            .foregroundColor(isSelected ? themeManager.adaptiveColor(.buttonText) : themeManager.adaptiveColor(.secondaryText))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? themeManager.adaptiveColor(.primary) : themeManager.adaptiveColor(.secondaryBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Form {
            Section("filter.start_date".localized) {
                DatePicker(
                    "filter.start_date".localized,
                    selection: $startDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
            }
            
            Section("filter.end_date".localized) {
                DatePicker(
                    "filter.end_date".localized,
                    selection: $endDate,
                    in: startDate...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
            }
        }
    }
}

struct GalleryCategoryFilterView: View {
    @Binding var selectedCategories: Set<LogCategory>
    let onSelectionChange: () -> Void
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Form {
            Section {
                Button(action: {
                    if selectedCategories.count == LogCategory.allCases.count {
                        selectedCategories.removeAll()
                    } else {
                        selectedCategories = Set(LogCategory.allCases)
                    }
                    onSelectionChange()
                }) {
                    HStack {
                        Text(selectedCategories.count == LogCategory.allCases.count ? 
                             "general.deselect_all".localized : 
                             "general.select_all".localized)
                        Spacer()
                        Image(systemName: selectedCategories.count == LogCategory.allCases.count ? 
                              "checkmark.square" : "square")
                    }
                    .foregroundColor(themeManager.adaptiveColor(.primary))
                }
            }
            
            Section {
                ForEach(LogCategory.allCases, id: \.self) { category in
                    HStack {
                        Circle()
                            .fill(themeManager.adaptiveColor(categoryColor(for: category)))
                            .frame(width: 12, height: 12)
                        
                        Text(category.displayName)
                            .foregroundColor(themeManager.adaptiveColor(.primaryText))
                            .font(.body)
                        
                        Spacer()
                        
                        if selectedCategories.contains(category) {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.adaptiveColor(.primary))
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                        onSelectionChange()
                    }
                }
            }
        }
    }
    
    private func categoryColor(for category: LogCategory) -> ThemeManager.ColorType {
        switch category {
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
}

#Preview {
    @Previewable @State var filter = GalleryFilter.all
    
    GalleryFilterBar(filter: $filter) {
        print("Filter changed")
    }
    .environmentObject(ThemeManager.shared)
    .padding()
}