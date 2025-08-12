//
//  ProjectListView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.lastModifiedDate, order: .reverse) private var projects: [Project]
    @State private var showingCreateProject = false
    @State private var showingSettings = false
    @State private var searchText = ""
    @EnvironmentObject private var themeManager: ThemeManager
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects.filter { !$0.isArchived }
        } else {
            return projects.filter { project in
                !project.isArchived &&
                (project.name.localizedCaseInsensitiveContains(searchText) ||
                 project.clientName.localizedCaseInsensitiveContains(searchText) ||
                 project.location.localizedCaseInsensitiveContains(searchText) ||
                 project.projectDescription.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                if filteredProjects.isEmpty {
                    emptyStateView
                } else {
                    projectListContent
                }
            }
            .navigationTitle("nav.projects".localized)
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "search.projects".localized)
            .onAppear {
                // Ensure navigation bar adapts to theme changes
                updateNavigationBarAppearance()
            }
            .onChange(of: themeManager.isDarkMode) { _, _ in
                updateNavigationBarAppearance()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateProject = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingCreateProject) {
                CreateProjectView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "building.2")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.primary.opacity(0.3))
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("project.no_projects".localized)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("project.no_projects_subtitle".localized)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
            
            Button(action: { showingCreateProject = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("project.create_project".localized)
                }
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.buttonText)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
        }
    }
    
    private var projectListContent: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(filteredProjects) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        ProjectCardView(project: project)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(DesignSystem.Spacing.screenPadding)
        }
    }
    
    private func updateNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Set colors based on current theme
        if themeManager.isDarkMode {
            appearance.backgroundColor = UIColor(DesignSystem.Colors.background)
            appearance.titleTextAttributes = [.foregroundColor: UIColor(DesignSystem.Colors.primaryText)]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(DesignSystem.Colors.primaryText)]
        } else {
            appearance.backgroundColor = UIColor(DesignSystem.Colors.background)
            appearance.titleTextAttributes = [.foregroundColor: UIColor(DesignSystem.Colors.primaryText)]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(DesignSystem.Colors.primaryText)]
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

struct ProjectCardView: View {
    @Bindable var project: Project
    
    private var lastModifiedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: project.lastModifiedDate, relativeTo: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(project.name)
                        .font(DesignSystem.Typography.projectTitle)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(2)
                    
                    if !project.clientName.isEmpty {
                        Text(project.clientName)
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("\(project.blueprints.count)")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text("project.blueprints_count".localized)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            if !project.location.isEmpty {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(project.location)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            HStack {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "doc.text")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("\(project.totalLogEntries) " + "project.logs_count".localized)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Text("project.updated".localized + " \(lastModifiedText)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .cardStyle()
    }
}

#Preview {
    ProjectListView()
        .modelContainer(for: [Project.self, Blueprint.self, LogEntry.self], inMemory: true)
}