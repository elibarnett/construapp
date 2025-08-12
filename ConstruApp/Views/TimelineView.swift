//
//  TimelineView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/5/25.
//

import SwiftUI
import SwiftData

struct TimelineView: View {
    let project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDateRange: DateRange = .all
    @State private var selectedCategories: Set<LogCategory> = Set(LogCategory.allCases)
    @State private var showingFilters = false
    @State private var searchText = ""
    
    private var filteredLogEntries: [LogEntry] {
        let allLogEntries = project.blueprints.flatMap { $0.logEntries }
        
        return allLogEntries
            .filter { logEntry in
                // Date filter
                let passesDateFilter = selectedDateRange.contains(logEntry.date)
                
                // Category filter
                let passesCategoryFilter = selectedCategories.contains(logEntry.category)
                
                // Search filter
                let passesSearchFilter = searchText.isEmpty || 
                    logEntry.title.localizedCaseInsensitiveContains(searchText) ||
                    logEntry.notes.localizedCaseInsensitiveContains(searchText)
                
                return passesDateFilter && passesCategoryFilter && passesSearchFilter
            }
            .sorted { $0.date > $1.date } // Most recent first
    }
    
    private var groupedLogEntries: [(String, [LogEntry])] {
        let calendar = Calendar.current
        let groupedDict = Dictionary(grouping: filteredLogEntries) { logEntry in
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: logEntry.date)
            let date = calendar.date(from: dateComponents) ?? logEntry.date
            return DateFormatter.timelineHeader.string(from: date)
        }
        
        return groupedDict.sorted { first, second in
            let firstDate = DateFormatter.timelineHeader.date(from: first.key) ?? Date.distantPast
            let secondDate = DateFormatter.timelineHeader.date(from: second.key) ?? Date.distantPast
            return firstDate > secondDate
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filters
                searchAndFilterSection
                
                // Timeline content
                if filteredLogEntries.isEmpty {
                    emptyStateView
                } else {
                    timelineScrollView
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                TimelineFiltersView(
                    selectedDateRange: $selectedDateRange,
                    selectedCategories: $selectedCategories
                )
            }
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                TextField("Search logs...", text: $searchText)
                    .font(DesignSystem.Typography.body)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            
            // Active filters summary
            if selectedDateRange != .all || selectedCategories.count != LogCategory.allCases.count {
                activeFiltersView
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .padding(.top, DesignSystem.Spacing.sm)
    }
    
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // Date range filter
                if selectedDateRange != .all {
                    FilterChipView(title: selectedDateRange.displayName, isRemovable: true) {
                        selectedDateRange = .all
                    }
                }
                
                // Category filters
                let excludedCategories = Set(LogCategory.allCases).subtracting(selectedCategories)
                if !excludedCategories.isEmpty && excludedCategories.count < LogCategory.allCases.count {
                    ForEach(Array(excludedCategories).sorted(by: { $0.displayName < $1.displayName }), id: \.self) { category in
                        FilterChipView(title: "Not \(category.displayName)", isRemovable: true) {
                            selectedCategories.insert(category)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        }
    }
    
    private var timelineScrollView: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.lg) {
                ForEach(groupedLogEntries, id: \.0) { dateString, entries in
                    timelineSection(dateString: dateString, entries: entries)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
    
    private func timelineSection(dateString: String, entries: [LogEntry]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Date header
            HStack {
                Text(dateString)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Rectangle()
                    .fill(DesignSystem.Colors.secondaryText.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Log entries for this date
            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(entries.sorted(by: { $0.date > $1.date }), id: \.id) { logEntry in
                    TimelineEntryView(logEntry: logEntry)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No Timeline Entries")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("No log entries match your current filters. Try adjusting your search or date range.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if selectedDateRange != .all || selectedCategories.count != LogCategory.allCases.count {
                Button("Clear All Filters") {
                    selectedDateRange = .all
                    selectedCategories = Set(LogCategory.allCases)
                    searchText = ""
                }
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.top, DesignSystem.Spacing.sm)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.screenPadding)
    }
}

struct TimelineEntryView: View {
    let logEntry: LogEntry
    
    var body: some View {
        NavigationLink(destination: LogEntryDetailView(logEntry: logEntry)) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                // Timeline indicator
                VStack {
                    Circle()
                        .fill(logEntry.category.color)
                        .frame(width: 12, height: 12)
                    
                    Rectangle()
                        .fill(DesignSystem.Colors.secondaryText.opacity(0.2))
                        .frame(width: 2)
                }
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(logEntry.title)
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .lineLimit(2)
                            
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Label(logEntry.category.displayName, systemImage: logEntry.category.iconName)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(logEntry.category.color)
                                
                                Text("•")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                Text(timeOnlyFormatter.string(from: logEntry.date))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                if let blueprintName = logEntry.blueprint?.name {
                                    Text("•")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                    
                                    Text(blueprintName)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Media indicators
                        if logEntry.hasMedia {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                if !logEntry.photos.isEmpty {
                                    Image(systemName: "photo")
                                        .font(.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                                if logEntry.hasVideo {
                                    Image(systemName: "video")
                                        .font(.caption)
                                        .foregroundColor(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    
                    if !logEntry.notes.isEmpty {
                        Text(logEntry.notes)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DesignSystem.Spacing.cardPadding)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timeOnlyFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct FilterChipView: View {
    let title: String
    let isRemovable: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primary)
            
            if isRemovable {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.primary.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.small)
    }
}

// MARK: - Date Range Enum
enum DateRange: String, CaseIterable {
    case all = "all"
    case today = "today"
    case yesterday = "yesterday"
    case thisWeek = "thisWeek"
    case lastWeek = "lastWeek"
    case thisMonth = "thisMonth"
    case lastMonth = "lastMonth"
    case last30Days = "last30Days"
    case last90Days = "last90Days"
    
    var displayName: String {
        switch self {
        case .all: return "All Time"
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .thisWeek: return "This Week"
        case .lastWeek: return "Last Week"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        }
    }
    
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .yesterday:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return false }
            return calendar.isDate(date, inSameDayAs: yesterday)
        case .thisWeek:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .lastWeek:
            guard let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else { return false }
            return calendar.isDate(date, equalTo: lastWeek, toGranularity: .weekOfYear)
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .lastMonth:
            guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
            return calendar.isDate(date, equalTo: lastMonth, toGranularity: .month)
        case .last30Days:
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return false }
            return date >= thirtyDaysAgo
        case .last90Days:
            guard let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: now) else { return false }
            return date >= ninetyDaysAgo
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let timelineHeader: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()
}

#Preview {
    let project = Project(name: "Sample Project", description: "A test project", clientName: "Test Client", location: "New York")
    
    return NavigationStack {
        TimelineView(project: project)
    }
    .modelContainer(for: [Project.self, Blueprint.self, LogEntry.self], inMemory: true)
}