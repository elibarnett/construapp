//
//  CategoryPickerView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: LogCategory
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
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
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.semibold)
                }
            }
        }
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
        Button(action: { 
            selectedCategory = category
            isPresented = false
        }) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Spacer()
                    
                    if selectedCategory == category {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                            .font(.title3)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(DesignSystem.Colors.secondaryText.opacity(0.3))
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
                selectedCategory == category ?
                category.color.opacity(0.1) :
                DesignSystem.Colors.secondaryBackground
            )
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        selectedCategory == category ?
                        category.color.opacity(0.5) :
                        Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CategoryPickerView(
        selectedCategory: .constant(.electrical),
        isPresented: .constant(true)
    )
}