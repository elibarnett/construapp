//
//  TimelineFiltersView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/5/25.
//

import SwiftUI

struct TimelineFiltersView: View {
    @Binding var selectedDateRange: DateRange
    @Binding var selectedCategories: Set<LogCategory>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                dateRangeSection
                categoriesSection
            }
            .navigationTitle("timeline.filters".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("general.reset".localized) {
                        selectedDateRange = .all
                        selectedCategories = Set(LogCategory.allCases)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("general.done".localized) {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var dateRangeSection: some View {
        Section {
            ForEach(DateRange.allCases, id: \.self) { range in
                Button(action: { selectedDateRange = range }) {
                    HStack {
                        Text(range.displayName)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Spacer()
                        
                        if selectedDateRange == range {
                            Image(systemName: "checkmark")
                                .foregroundColor(DesignSystem.Colors.primary)
                                .font(.body.weight(.semibold))
                        }
                    }
                }
            }
        } header: {
            Text("filter.date_range".localized)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
    }
    
    private var categoriesSection: some View {
        Section {
            // Select/Deselect All
            Button(action: toggleAllCategories) {
                HStack {
                    Text(allCategoriesSelected ? "filter.deselect_all".localized : "filter.select_all".localized)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Spacer()
                    
                    if allCategoriesSelected {
                        Image(systemName: "checkmark.square.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                    } else if selectedCategories.isEmpty {
                        Image(systemName: "square")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    } else {
                        Image(systemName: "minus.square.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
            
            Divider()
            
            // Category groups
            categoryGroup(title: "category.group.construction".localized, categories: LogCategory.constructionCategories)
            categoryGroup(title: "category.group.finishing".localized, categories: LogCategory.finishingCategories)
            categoryGroup(title: "category.group.other".localized, categories: LogCategory.otherCategories)
            
        } header: {
            HStack {
                Text("filter.categories".localized)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Text("\(selectedCategories.count) of \(LogCategory.allCases.count) selected")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
    
    private func categoryGroup(title: String, categories: [LogCategory]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.primary)
                .fontWeight(.medium)
                .padding(.top, DesignSystem.Spacing.sm)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(categories, id: \.self) { category in
                    categoryRow(category: category)
                }
            }
        }
    }
    
    private func categoryRow(category: LogCategory) -> some View {
        Button(action: { toggleCategory(category) }) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text(category.shortDescription)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if selectedCategories.contains(category) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    private var allCategoriesSelected: Bool {
        selectedCategories.count == LogCategory.allCases.count
    }
    
    private func toggleAllCategories() {
        if allCategoriesSelected {
            selectedCategories.removeAll()
        } else {
            selectedCategories = Set(LogCategory.allCases)
        }
    }
    
    private func toggleCategory(_ category: LogCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}

#Preview {
    @Previewable @State var selectedDateRange: DateRange = .all
    @Previewable @State var selectedCategories: Set<LogCategory> = Set(LogCategory.allCases)
    
    return TimelineFiltersView(
        selectedDateRange: $selectedDateRange,
        selectedCategories: $selectedCategories
    )
}