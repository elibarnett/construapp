//
//  CategoryOverviewView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI

struct CategoryOverviewView: View {
    let blueprint: Blueprint
    @Binding var selectedCategories: Set<LogCategory>
    @Environment(\.dismiss) private var dismiss
    
    private var categoryStats: [CategoryStat] {
        LogCategory.allCases.compactMap { category in
            let entries = blueprint.logEntries.filter { $0.category == category }
            guard !entries.isEmpty else { return nil }
            
            return CategoryStat(
                category: category,
                count: entries.count,
                hasMedia: entries.contains { $0.hasMedia },
                latestDate: entries.map { $0.date }.max() ?? Date()
            )
        }.sorted { $0.count > $1.count }
    }
    
    private var totalLogCount: Int {
        blueprint.logEntries.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Summary Header
                    summarySection
                    
                    // Category Statistics
                    if !categoryStats.isEmpty {
                        categoryStatsSection
                    } else {
                        emptyStateSection
                    }
                }
                .padding(DesignSystem.Spacing.screenPadding)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Category Overview".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("general.done".localized) {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: filterByConstruction) {
                            Label("filter.construction_only".localized, systemImage: "building.2")
                        }
                        
                        Button(action: filterByFinishing) {
                            Label("filter.finishing_only".localized, systemImage: "paintbrush")
                        }
                        
                        Button(action: filterBySafety) {
                            Label("filter.safety_issues".localized, systemImage: "exclamationmark.triangle")
                        }
                        
                        Divider()
                        
                        Button(action: selectAllCategories) {
                            Label("filter.show_all".localized, systemImage: "eye")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("stats.summary".localized)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            HStack(spacing: DesignSystem.Spacing.lg) {
                summaryCard(
                    title: "project.total_logs".localized,
                    value: "\(totalLogCount)",
                    icon: "note.text",
                    color: DesignSystem.Colors.primary
                )
                
                summaryCard(
                    title: "stats.categories".localized,
                    value: "\(categoryStats.count)",
                    icon: "square.grid.3x3",
                    color: DesignSystem.Colors.secondary
                )
                
                summaryCard(
                    title: "log.with_media".localized,
                    value: "\(blueprint.logEntries.filter { $0.hasMedia }.count)",
                    icon: "camera.fill",
                    color: DesignSystem.Colors.primary
                )
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .cardStyle()
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .fontWeight(.semibold)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var categoryStatsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Categories")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(categoryStats, id: \.category) { stat in
                    categoryStatRow(stat)
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .cardStyle()
    }
    
    private func categoryStatRow(_ stat: CategoryStat) -> some View {
        Button(action: { toggleCategory(stat.category) }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Category Icon and Color
                Image(systemName: stat.category.iconName)
                    .font(.title2)
                    .foregroundColor(stat.category.color)
                    .frame(width: 32, height: 32)
                    .background(stat.category.color.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.small)
                
                // Category Info
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text(stat.category.displayName)
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Spacer()
                        
                        // Count Badge
                        Text("\(stat.count)")
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.buttonText)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(stat.category.color)
                            .cornerRadius(12)
                    }
                    
                    HStack {
                        Text(stat.category.shortDescription)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        // Media Indicator
                        if stat.hasMedia {
                            Image(systemName: "camera.fill")
                                .font(.caption2)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        
                        // Selection Indicator
                        Image(systemName: selectedCategories.contains(stat.category) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedCategories.contains(stat.category) ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText.opacity(0.5))
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                selectedCategories.contains(stat.category) ?
                stat.category.color.opacity(0.05) :
                Color.clear
            )
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "square.grid.3x3")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No Log Entries")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Start adding log entries by tapping on the blueprint to create pins with categorized documentation.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
    
    private func toggleCategory(_ category: LogCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    private func filterByConstruction() {
        selectedCategories = Set(LogCategory.constructionCategories.filter { category in
            categoryStats.contains { $0.category == category }
        })
        dismiss()
    }
    
    private func filterByFinishing() {
        selectedCategories = Set(LogCategory.finishingCategories.filter { category in
            categoryStats.contains { $0.category == category }
        })
        dismiss()
    }
    
    private func filterBySafety() {
        selectedCategories = Set([.safety]).intersection(Set(categoryStats.map { $0.category }))
        dismiss()
    }
    
    private func selectAllCategories() {
        selectedCategories = Set(categoryStats.map { $0.category })
        dismiss()
    }
}

struct CategoryStat {
    let category: LogCategory
    let count: Int
    let hasMedia: Bool
    let latestDate: Date
}

#Preview {
    let blueprint = Blueprint(
        name: "Sample Blueprint",
        fileName: "sample.pdf",
        pdfData: Data(),
        pageCount: 1,
        pdfWidth: 612,
        pdfHeight: 792
    )
    
    return CategoryOverviewView(
        blueprint: blueprint,
        selectedCategories: .constant(Set([.electrical, .plumbing]))
    )
}