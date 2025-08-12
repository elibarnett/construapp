//
//  AddBlueprintView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct AddBlueprintView: View {
    let project: Project
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var blueprintName = ""
    @State private var selectedPDFData: Data?
    @State private var selectedFileName = ""
    @State private var isDocumentPickerPresented = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    private var isValidForm: Bool {
        !blueprintName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedPDFData != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Blueprint Name", text: $blueprintName)
                        .font(DesignSystem.Typography.bodyMedium)
                } header: {
                    Text("Blueprint Details")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Section {
                    if selectedPDFData != nil {
                        selectedPDFView
                    } else {
                        uploadPromptView
                    }
                } header: {
                    Text("PDF File")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(DesignSystem.Colors.error)
                            .font(DesignSystem.Typography.body)
                    }
                }
            }
            .navigationTitle("Add Blueprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .disabled(isProcessing)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Add") {
                            addBlueprint()
                        }
                        .disabled(!isValidForm)
                        .foregroundColor(isValidForm ? DesignSystem.Colors.primary : DesignSystem.Colors.secondary)
                        .fontWeight(isValidForm ? .semibold : .regular)
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isDocumentPickerPresented,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            print("DEBUG: File importer callback triggered")
            handleFileSelection(result)
        }
    }
    
    private var uploadPromptView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.primary.opacity(0.3))
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Select PDF Blueprint")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text("Choose a PDF file from your device")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { 
                print("DEBUG: Browse Files button tapped")
                isDocumentPickerPresented = true 
            }) {
                HStack {
                    Image(systemName: "folder")
                    Text("Browse Files")
                }
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.buttonText)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(DesignSystem.CornerRadius.medium)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
    
    private var selectedPDFView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(DesignSystem.Colors.primary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(selectedFileName)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                        .lineLimit(2)
                    
                    if let data = selectedPDFData {
                        Text(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Button(action: { selectedPDFData = nil; selectedFileName = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            
            Button(action: { isDocumentPickerPresented = true }) {
                Text("Choose Different File")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            print("DEBUG: File selection successful, URLs: \(urls)")
            guard let url = urls.first else { 
                print("DEBUG: No URL found in selection")
                return 
            }
            
            print("DEBUG: Selected URL: \(url)")
            print("DEBUG: URL is reachable: \(url.isFileURL)")
            
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let data = try Data(contentsOf: url)
                    print("DEBUG: Successfully loaded PDF data, size: \(data.count) bytes")
                    selectedPDFData = data
                    selectedFileName = url.lastPathComponent
                    
                    // Auto-fill blueprint name if empty
                    if blueprintName.isEmpty {
                        blueprintName = url.deletingPathExtension().lastPathComponent
                    }
                    
                    print("DEBUG: Set blueprint name to: \(blueprintName)")
                    errorMessage = nil
                } catch {
                    print("DEBUG: Failed to load PDF data: \(error)")
                    errorMessage = "Failed to load PDF file: \(error.localizedDescription)"
                }
            } else {
                print("DEBUG: Failed to access security scoped resource")
                errorMessage = "Unable to access the selected file"
            }
            
        case .failure(let error):
            print("DEBUG: File selection failed: \(error)")
            errorMessage = "File selection failed: \(error.localizedDescription)"
        }
    }
    
    private func addBlueprint() {
        guard let pdfData = selectedPDFData else { 
            print("DEBUG: No PDF data available")
            return 
        }
        
        print("DEBUG: Starting blueprint addition process")
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                print("DEBUG: Processing PDF data...")
                // Process PDF to get page count and dimensions
                let (pageCount, width, height) = try await processPDF(data: pdfData)
                print("DEBUG: PDF processed successfully - Pages: \(pageCount), Size: \(width)x\(height)")
                
                await MainActor.run {
                    print("DEBUG: Creating blueprint object...")
                    let blueprint = Blueprint(
                        name: blueprintName.trimmingCharacters(in: .whitespacesAndNewlines),
                        fileName: selectedFileName,
                        pdfData: pdfData,
                        pageCount: pageCount,
                        pdfWidth: width,
                        pdfHeight: height
                    )
                    
                    blueprint.project = project
                    project.blueprints.append(blueprint)
                    project.updateLastModified()
                    
                    modelContext.insert(blueprint)
                    print("DEBUG: Blueprint inserted into context")
                    
                    do {
                        try modelContext.save()
                        print("DEBUG: Blueprint saved successfully")
                        dismiss()
                    } catch {
                        print("DEBUG: Failed to save blueprint: \(error)")
                        errorMessage = "Failed to save blueprint: \(error.localizedDescription)"
                        isProcessing = false
                    }
                }
            } catch {
                print("DEBUG: Failed to process PDF: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to process PDF: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
    
    private func processPDF(data: Data) async throws -> (pageCount: Int, width: Double, height: Double) {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                print("DEBUG: Creating PDFDocument from data of size: \(data.count)")
                guard let document = PDFDocument(data: data) else {
                    print("DEBUG: Failed to create PDFDocument")
                    continuation.resume(throwing: PDFError.invalidDocument)
                    return
                }
                
                let pageCount = document.pageCount
                print("DEBUG: PDF document has \(pageCount) pages")
                
                // Get dimensions from first page
                var width: Double = 612 // Default letter size
                var height: Double = 792
                
                if let firstPage = document.page(at: 0) {
                    let bounds = firstPage.bounds(for: .mediaBox)
                    width = Double(bounds.width)
                    height = Double(bounds.height)
                    print("DEBUG: First page dimensions: \(width) x \(height)")
                } else {
                    print("DEBUG: No first page found, using defaults")
                }
                
                continuation.resume(returning: (pageCount, width, height))
            }
        }
    }
}

enum PDFError: Error, LocalizedError {
    case invalidDocument
    
    var errorDescription: String? {
        switch self {
        case .invalidDocument:
            return "The selected file is not a valid PDF document"
        }
    }
}

#Preview {
    let project = Project(name: "Sample Project")
    
    return AddBlueprintView(project: project)
        .modelContainer(for: [Project.self, Blueprint.self, LogEntry.self], inMemory: true)
}