//
//  CreateProjectView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import SwiftData

struct CreateProjectView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName = ""
    @State private var description = ""
    @State private var clientName = ""
    @State private var location = ""
    
    private var isValidForm: Bool {
        !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("project.name".localized, text: $projectName)
                        .font(DesignSystem.Typography.bodyMedium)
                    
                    TextField("project.client_name".localized, text: $clientName)
                        .font(DesignSystem.Typography.body)
                    
                    TextField("project.location".localized, text: $location)
                        .font(DesignSystem.Typography.body)
                    
                    TextField("project.description".localized, text: $description, axis: .vertical)
                        .font(DesignSystem.Typography.body)
                        .lineLimit(3...6)
                } header: {
                    Text("project.details".localized)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .navigationTitle("nav.new_project".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("general.cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("general.create".localized) {
                        createProject()
                    }
                    .disabled(!isValidForm)
                    .foregroundColor(isValidForm ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                    .fontWeight(isValidForm ? .semibold : .regular)
                }
            }
        }
    }
    
    private func createProject() {
        let newProject = Project(
            name: projectName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            location: location.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        modelContext.insert(newProject)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error appropriately in production
            print("Failed to save project: \(error)")
        }
    }
}

#Preview {
    CreateProjectView()
        .modelContainer(for: [Project.self, Blueprint.self, LogEntry.self], inMemory: true)
}