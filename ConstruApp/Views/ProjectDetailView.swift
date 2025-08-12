//
//  ProjectDetailView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddBlueprint = false
    @State private var showingEditProject = false
    @State private var showingGallery = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Project Header
                projectHeaderView
                
                // Project Stats
                projectStatsView
                
                // Blueprints Section
                blueprintsSection
                
                // Recent Activity
                recentActivitySection
            }
            .padding(DesignSystem.Spacing.screenPadding)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // Gallery button
                    Button(action: { showingGallery = true }) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .disabled(project.totalMediaItems == 0)
                    
                    // Menu button
                    Menu {
                        Button(action: { showingEditProject = true }) {
                            Label("action.edit_project".localized, systemImage: "pencil")
                        }
                        
                        Button(action: { showingAddBlueprint = true }) {
                            Label("action.add_blueprint".localized, systemImage: "doc.badge.plus")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: archiveProject) {
                            Label("action.archive_project".localized, systemImage: "archivebox")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddBlueprint) {
            AddBlueprintView(project: project)
        }
        .sheet(isPresented: $showingEditProject) {
            EditProjectView(project: project)
        }
        .sheet(isPresented: $showingGallery) {
            MediaGalleryView(context: .project(project), modelContext: modelContext)
        }
    }
    
    private var projectHeaderView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            if !project.clientName.isEmpty {
                Text(project.clientName)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            if !project.location.isEmpty {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(project.location)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            if !project.projectDescription.isEmpty {
                Text(project.projectDescription)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .cardStyle()
    }
    
    private var projectStatsView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                StatCardView(
                    title: "nav.blueprints".localized,
                    value: "\(project.blueprints.count)",
                    icon: "doc.text",
                    color: DesignSystem.Colors.primary
                )
                
                StatCardView(
                    title: "project.total_logs".localized,
                    value: "\(project.totalLogEntries)",
                    icon: "note.text",
                    color: DesignSystem.Colors.secondary
                )
                
                StatCardView(
                    title: "project.days_active".localized,
                    value: "\(daysSinceCreation)",
                    icon: "calendar",
                    color: DesignSystem.Colors.primary.opacity(0.7)
                )
            }
            
            // Media statistics row
            if project.totalMediaItems > 0 {
                HStack(spacing: DesignSystem.Spacing.md) {
                    StatCardView(
                        title: "general.photos".localized,
                        value: "\(project.totalPhotos)",
                        icon: "photo",
                        color: DesignSystem.Colors.primary.opacity(0.8)
                    )
                    
                    StatCardView(
                        title: "general.videos".localized,
                        value: "\(project.totalVideos)",
                        icon: "video",
                        color: DesignSystem.Colors.secondary.opacity(0.8)
                    )
                    
                    Button(action: { showingGallery = true }) {
                        StatCardView(
                            title: "nav.media_gallery".localized,
                            value: "\(project.totalMediaItems)",
                            icon: "photo.on.rectangle.angled",
                            color: DesignSystem.Colors.primary
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var blueprintsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("nav.blueprints".localized)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button(action: { showingAddBlueprint = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            if project.blueprints.isEmpty {
                EmptyBlueprintsView {
                    showingAddBlueprint = true
                }
            } else {
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(project.blueprints) { blueprint in
                        NavigationLink(destination: BlueprintViewerView(blueprint: blueprint)) {
                            BlueprintRowView(blueprint: blueprint)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("log.recent_activity".localized)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                NavigationLink(destination: TimelineView(project: project)) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("log.view_timeline".localized)
                            .font(DesignSystem.Typography.callout)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            if project.recentLogEntries.isEmpty {
                Text("log.no_activity".localized)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(DesignSystem.Spacing.cardPadding)
                    .cardStyle()
            } else {
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(project.recentLogEntries.prefix(5), id: \.id) { logEntry in
                        RecentActivityRowView(logEntry: logEntry)
                    }
                    
                    if project.recentLogEntries.count > 5 {
                        NavigationLink(destination: TimelineView(project: project)) {
                            HStack {
                                Spacer()
                                Text("log.view_all_entries".localized(args: project.totalLogEntries))
                                    .font(DesignSystem.Typography.callout)
                                    .foregroundColor(DesignSystem.Colors.primary)
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.primary)
                                Spacer()
                            }
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.primary.opacity(0.05))
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: project.createdDate, to: Date()).day ?? 0
    }
    
    private func archiveProject() {
        project.isArchived = true
        project.updateLastModified()
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to archive project: \(error)")
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
}

// Navigation to BlueprintViewerView is handled by the NavigationLink

struct EditProjectView: View {
    @Bindable var project: Project
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Edit Project functionality coming soon")
                .navigationTitle("nav.edit_project".localized)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("general.cancel".localized) { dismiss() }
                    }
                }
        }
    }
}

struct EmptyBlueprintsView: View {
    let onAddBlueprint: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "doc.badge.plus")
                .font(.largeTitle)
                .foregroundColor(DesignSystem.Colors.primary.opacity(0.3))
            
            Text("empty.blueprints".localized)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Button(action: onAddBlueprint) {
                Text("blueprint.add_first".localized)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .cardStyle()
    }
}

struct BlueprintRowView: View {
    let blueprint: Blueprint
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(DesignSystem.Colors.primary)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(blueprint.name)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                HStack {
                    Text("\(blueprint.logEntries.count) logs")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    if blueprint.totalMediaItems > 0 {
                        Text("•")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        HStack(spacing: 2) {
                            if blueprint.totalPhotos > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "photo")
                                        .font(.caption2)
                                    Text("\(blueprint.totalPhotos)")
                                }
                            }
                            if blueprint.totalVideos > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "video")
                                        .font(.caption2)
                                    Text("\(blueprint.totalVideos)")
                                }
                            }
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.primary.opacity(0.8))
                    }
                    
                    Text("• \(blueprint.fileSize)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .font(.caption)
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
}

struct RecentActivityRowView: View {
    let logEntry: LogEntry
    
    var body: some View {
        HStack {
            Image(systemName: logEntry.category.iconName)
                .foregroundColor(logEntry.category.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(logEntry.title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .lineLimit(1)
                
                Text(logEntry.displayDate)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
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
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
}

#Preview {
    let project = Project(name: "Sample Project", description: "A test project", clientName: "Test Client", location: "New York")
    
    return NavigationStack {
        ProjectDetailView(project: project)
    }
    .modelContainer(for: [Project.self, Blueprint.self, LogEntry.self], inMemory: true)
}