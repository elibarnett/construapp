//
//  CategoryFilterView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI

struct CategoryFilterView: View {
    @Binding var selectedCategories: Set<LogCategory>
    @Binding var isPresented: Bool
    
    @State private var tempSelectedCategories: Set<LogCategory>
    
    init(selectedCategories: Binding<Set<LogCategory>>, isPresented: Binding<Bool>) {
        self._selectedCategories = selectedCategories
        self._isPresented = isPresented
        self._tempSelectedCategories = State(initialValue: selectedCategories.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // Quick Actions
                    quickActionsSection
                    
                    // Construction Categories
                    categorySection(
                        title: "Construction",
                        categories: LogCategory.constructionCategories
                    )
                    
                    // Finishing Categories
                    categorySection(
                        title: "Finishing",
                        categories: LogCategory.finishingCategories
                    )
                    
                    // Other Categories
                    categorySection(
                        title: "Other",
                        categories: LogCategory.otherCategories
                    )
                }
                .padding(DesignSystem.Spacing.screenPadding)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Filter Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        selectedCategories = tempSelectedCategories
                        isPresented = false
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Quick Actions")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Button(action: selectAll) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Select All")
                    }
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                
                Button(action: clearAll) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Clear All")
                    }
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                
                Spacer()
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .cardStyle()
    }
    
    private func categorySection(title: String, categories: [LogCategory]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 2), spacing: DesignSystem.Spacing.md) {
                ForEach(categories, id: \.self) { category in
                    categoryCard(category)
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .cardStyle()
    }
    
    private func categoryCard(_ category: LogCategory) -> some View {
        Button(action: { toggleCategory(category) }) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Spacer()
                    
                    if tempSelectedCategories.contains(category) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                            .font(.title3)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.5))
                            .font(.title3)
                    }
                }
                
                Image(systemName: category.iconName)
                    .font(.title)
                    .foregroundColor(category.color)
                    .frame(height: 32)
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(category.displayName)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text(category.shortDescription)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                tempSelectedCategories.contains(category) ?
                category.color.opacity(0.1) :
                DesignSystem.Colors.secondaryBackground
            )
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        tempSelectedCategories.contains(category) ?
                        category.color.opacity(0.3) :
                        Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleCategory(_ category: LogCategory) {
        if tempSelectedCategories.contains(category) {
            tempSelectedCategories.remove(category)
        } else {
            tempSelectedCategories.insert(category)
        }
    }
    
    private func selectAll() {
        tempSelectedCategories = Set(LogCategory.allCases)
    }
    
    private func clearAll() {
        tempSelectedCategories.removeAll()
    }
}

#Preview {
    CategoryFilterView(
        selectedCategories: .constant(Set([.electrical, .plumbing])),
        isPresented: .constant(true)
    )
}