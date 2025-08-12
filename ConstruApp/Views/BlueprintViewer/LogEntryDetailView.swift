//
//  LogEntryDetailView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import SwiftData

struct LogEntryDetailView: View {
    @Bindable var logEntry: LogEntry
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var selectedPhotoIndex: Int?
    @State private var showingMediaPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header with category and date
                headerView
                
                // Notes section
                if !logEntry.notes.isEmpty {
                    notesSection
                }
                
                // Location information
                locationSection
                
                // Media section (placeholder for Phase 5)
                mediaSection
                
                Spacer(minLength: DesignSystem.Spacing.xl)
            }
            .padding(DesignSystem.Spacing.screenPadding)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(logEntry.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { showingEditView = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Menu {
                    Button(action: { showingEditView = true }) {
                        Label("Edit Log Entry", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Log Entry", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditLogEntryView(logEntry: logEntry)
        }
        .alert("Delete Log Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteLogEntry()
            }
        } message: {
            Text("Are you sure you want to delete this log entry? This action cannot be undone.")
        }
        .sheet(isPresented: $showingMediaPicker) {
            MediaPickerView(
                isPresented: $showingMediaPicker,
                onPhotosSelected: { photoDataArray in
                    for photoData in photoDataArray {
                        addPhoto(photoData)
                    }
                },
                onVideoCapture: { data, fileName in
                    addVideo(data, fileName: fileName)
                }
            )
        }
        .sheet(item: Binding<PhotoPreviewItem?>(
            get: { selectedPhotoIndex.map { PhotoPreviewItem(photoData: logEntry.photos[$0], index: $0) } },
            set: { _ in selectedPhotoIndex = nil }
        )) { item in
            PhotoPreviewView(photoData: item.photoData) {
                removePhoto(at: item.index)
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                // Category icon and color
                Image(systemName: logEntry.category.iconName)
                    .font(.title2)
                    .foregroundColor(logEntry.category.color)
                    .frame(width: 32, height: 32)
                    .background(logEntry.category.color.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.small)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(logEntry.category.displayName)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    Text(logEntry.displayDate)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Spacer()
                
                // Media indicator
                if logEntry.hasMedia {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        if !logEntry.photos.isEmpty {
                            Image(systemName: "photo")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        if logEntry.hasVideo {
                            Image(systemName: "video")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .cardStyle()
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Notes")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Text(logEntry.notes)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Location")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text(logEntry.blueprint?.name ?? "Unknown Blueprint")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                HStack {
                    Image(systemName: "doc.plaintext")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("Page \(logEntry.pageNumber)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Text("Position: \(String(format: "%.1f", logEntry.xCoordinate * 100))%, \(String(format: "%.1f", logEntry.yCoordinate * 100))%")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Media")
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button(action: { showingMediaPicker = true }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            if logEntry.hasMedia {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    // Photos Grid
                    if !logEntry.photos.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Photos (\(logEntry.photoCount))")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.sm), count: 3), spacing: DesignSystem.Spacing.sm) {
                                ForEach(Array(logEntry.photos.enumerated()), id: \.offset) { index, photoData in
                                    photoThumbnail(photoData, at: index)
                                }
                            }
                        }
                    }
                    
                    // Video
                    if logEntry.hasVideo, let fileName = logEntry.videoFileName {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Video")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            HStack {
                                Image(systemName: "video.fill")
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fileName)
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.primary)
                                    
                                    if let videoData = logEntry.videoData {
                                        let sizeInMB = Double(videoData.count) / (1024 * 1024)
                                        Text(String(format: "%.1f MB", sizeInMB))
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: { removeVideo() }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(DesignSystem.Colors.error)
                                }
                            }
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.secondaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                    }
                }
            } else {
                Button(action: { showingMediaPicker = true }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Add Photos or Video")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
    
    private func deleteLogEntry() {
        // Remove from blueprint
        if let blueprint = logEntry.blueprint,
           let index = blueprint.logEntries.firstIndex(of: logEntry) {
            blueprint.logEntries.remove(at: index)
            blueprint.project?.updateLastModified()
        }
        
        // Delete from context
        modelContext.delete(logEntry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete log entry: \(error)")
        }
    }
    
    private func photoThumbnail(_ photoData: Data, at index: Int) -> some View {
        Button(action: { selectedPhotoIndex = index }) {
            if let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(DesignSystem.CornerRadius.medium)
            } else {
                Rectangle()
                    .fill(DesignSystem.Colors.secondaryBackground)
                    .frame(width: 80, height: 80)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
            }
        }
    }
    
    private func addPhoto(_ data: Data) {
        logEntry.addPhoto(data)
        saveContext()
    }
    
    private func removePhoto(at index: Int) {
        logEntry.removePhoto(at: index)
        saveContext()
    }
    
    private func addVideo(_ data: Data, fileName: String) {
        logEntry.setVideo(data, fileName: fileName)
        saveContext()
    }
    
    private func removeVideo() {
        logEntry.removeVideo()
        saveContext()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save media changes: \(error)")
        }
    }
}

struct PhotoPreviewItem: Identifiable {
    let id = UUID()
    let photoData: Data
    let index: Int
}

struct PhotoPreviewView: View {
    let photoData: Data
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .ignoresSafeArea()
                } else {
                    Text("Unable to load image")
                        .foregroundColor(DesignSystem.Colors.buttonText)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.buttonText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDelete()
                        dismiss()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(DesignSystem.Colors.buttonText)
                    }
                }
            }
        }
    }
}

struct EditLogEntryView: View {
    @Bindable var logEntry: LogEntry
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedCategory: LogCategory = .general
    @State private var selectedDate = Date()
    @State private var isProcessing = false
    
    private var isValidForm: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Log Title", text: $title)
                        .font(DesignSystem.Typography.bodyMedium)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(LogCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    
                } header: {
                    Text("Log Details")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Section {
                    TextField("Notes and observations", text: $notes, axis: .vertical)
                        .font(DesignSystem.Typography.body)
                        .lineLimit(3...8)
                } header: {
                    Text("Notes")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .navigationTitle("Edit Log Entry")
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
                        Button("Save") {
                            saveChanges()
                        }
                        .disabled(!isValidForm)
                        .foregroundColor(isValidForm ? DesignSystem.Colors.primary : DesignSystem.Colors.secondary)
                        .fontWeight(isValidForm ? .semibold : .regular)
                    }
                }
            }
            .onAppear {
                title = logEntry.title
                notes = logEntry.notes
                selectedCategory = logEntry.category
                selectedDate = logEntry.date
            }
        }
    }
    
    private func saveChanges() {
        isProcessing = true
        
        logEntry.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        logEntry.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        logEntry.category = selectedCategory
        logEntry.date = selectedDate
        
        logEntry.blueprint?.project?.updateLastModified()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save changes: \(error)")
            isProcessing = false
        }
    }
}

#Preview {
    let logEntry = LogEntry(
        title: "Sample Log Entry",
        notes: "This is a sample log entry with some notes about the construction progress.",
        category: .electrical,
        xCoordinate: 0.5,
        yCoordinate: 0.3,
        pageNumber: 1
    )
    
    return NavigationStack {
        LogEntryDetailView(logEntry: logEntry)
    }
    .modelContainer(for: [Project.self, Blueprint.self, LogEntry.self], inMemory: true)
}