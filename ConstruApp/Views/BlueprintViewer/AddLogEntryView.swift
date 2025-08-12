//
//  AddLogEntryView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import SwiftData

struct AddLogEntryView: View {
    let blueprint: Blueprint
    let xCoordinate: Double
    let yCoordinate: Double
    let pageNumber: Int
    
    init(blueprint: Blueprint, xCoordinate: Double, yCoordinate: Double, pageNumber: Int) {
        self.blueprint = blueprint
        self.xCoordinate = xCoordinate
        self.yCoordinate = yCoordinate
        self.pageNumber = pageNumber
        print("DEBUG: AddLogEntryView - initialized with coordinates: x=\(xCoordinate), y=\(yCoordinate)")
    }
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedCategory: LogCategory = .general
    @State private var selectedDate = Date()
    @State private var isProcessing = false
    @State private var photos: [Data] = []
    @State private var videoData: Data?
    @State private var videoFileName: String?
    @State private var showingMediaPicker = false
    @State private var showingCategoryPicker = false
    
    private var isValidForm: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Force form background to use theme colors
                Color.clear
                    .listRowBackground(DesignSystem.Colors.background)
                    .frame(height: 0)
                Section {
                    TextField(NSLocalizedString("log.title", comment: ""), text: $title)
                        .font(DesignSystem.Typography.bodyMedium)
                    
                    Button(action: { showingCategoryPicker = true }) {
                        HStack {
                            Image(systemName: selectedCategory.iconName)
                                .foregroundColor(selectedCategory.color)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedCategory.displayName)
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                
                                Text(selectedCategory.shortDescription)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                                .font(.caption)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                    
                    DatePicker(NSLocalizedString("log.date", comment: ""), selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    
                } header: {
                    Text(NSLocalizedString("log.details", comment: ""))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Section {
                    TextField(NSLocalizedString("log.notes_observations", comment: ""), text: $notes, axis: .vertical)
                        .font(DesignSystem.Typography.body)
                        .lineLimit(3...8)
                } header: {
                    Text(NSLocalizedString("log.notes", comment: ""))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Section {
                    mediaSection
                } header: {
                    Text(NSLocalizedString("media.photos", comment: ""))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Section {
                    locationInfoView
                } header: {
                    Text(NSLocalizedString("log.location", comment: ""))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            .navigationTitle(NSLocalizedString("log.add_log", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("general.cancel", comment: "")) {
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
                        Button(NSLocalizedString("general.add", comment: "")) {
                            addLogEntry()
                        }
                        .disabled(!isValidForm)
                        .foregroundColor(isValidForm ? DesignSystem.Colors.primary : DesignSystem.Colors.secondary)
                        .fontWeight(isValidForm ? .semibold : .regular)
                    }
                }
            }
        }
        .sheet(isPresented: $showingMediaPicker) {
            MediaPickerView(
                isPresented: $showingMediaPicker,
                onPhotosSelected: { photoDataArray in
                    photos.append(contentsOf: photoDataArray)
                },
                onVideoCapture: { data, fileName in
                    videoData = data
                    videoFileName = fileName
                }
            )
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(
                selectedCategory: $selectedCategory,
                isPresented: $showingCategoryPicker
            )
        }
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        .onAppear {
            updateNavigationBarAppearance()
        }
        .onChange(of: themeManager.isDarkMode) { _, _ in
            updateNavigationBarAppearance()
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
    
    private var locationInfoView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(DesignSystem.Colors.primary)
                Text(blueprint.name)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.primaryText)
            }
            
            HStack {
                Image(systemName: "doc.plaintext")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                Text(String(format: NSLocalizedString("log.page", comment: ""), pageNumber))
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            
            HStack {
                Image(systemName: "location")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                Text(String(format: NSLocalizedString("log.position", comment: ""), xCoordinate * 100, yCoordinate * 100))
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    private var mediaSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Add Media Button
            Button(action: { showingMediaPicker = true }) {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text(NSLocalizedString("media.add_photos_video", comment: ""))
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.primary)
                    Spacer()
                    Image(systemName: "plus.circle")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.vertical, DesignSystem.Spacing.sm)
            }
            
            // Display added media
            if !photos.isEmpty || videoData != nil {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    // Photos
                    if !photos.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("\(NSLocalizedString("media.photos", comment: "")) (\(photos.count))")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    ForEach(Array(photos.enumerated()), id: \.offset) { index, photoData in
                                        photoThumbnail(photoData, at: index)
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }
                    }
                    
                    // Video
                    if let _ = videoData, let fileName = videoFileName {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text(NSLocalizedString("media.video", comment: ""))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            HStack {
                                Image(systemName: "video.fill")
                                    .foregroundColor(DesignSystem.Colors.primary)
                                Text(fileName)
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.primaryText)
                                Spacer()
                                Button(action: { removeVideo() }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.error)
                                }
                            }
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.secondaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.small)
                        }
                    }
                }
            }
        }
    }
    
    private func photoThumbnail(_ photoData: Data, at index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            if let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(DesignSystem.CornerRadius.small)
            } else {
                Rectangle()
                    .fill(DesignSystem.Colors.secondaryBackground)
                    .frame(width: 60, height: 60)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
            }
            
            Button(action: { removePhoto(at: index) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.buttonText)
                    .background(Circle().fill(DesignSystem.Colors.background.opacity(0.8)))
            }
            .offset(x: 8, y: -8)
        }
    }
    
    private func removePhoto(at index: Int) {
        photos.remove(at: index)
    }
    
    private func removeVideo() {
        videoData = nil
        videoFileName = nil
    }
    
    private func addLogEntry() {
        isProcessing = true
        
        let logEntry = LogEntry(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            date: selectedDate,
            category: selectedCategory,
            xCoordinate: xCoordinate,
            yCoordinate: yCoordinate,
            pageNumber: pageNumber
        )
        
        // Add media to log entry
        logEntry.photos = photos
        logEntry.videoData = videoData
        logEntry.videoFileName = videoFileName
        
        logEntry.blueprint = blueprint
        blueprint.logEntries.append(logEntry)
        blueprint.project?.updateLastModified()
        
        modelContext.insert(logEntry)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error appropriately in production
            print("Failed to save log entry: \(error)")
            isProcessing = false
        }
    }
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
    
    return AddLogEntryView(
        blueprint: blueprint,
        xCoordinate: 0.5,
        yCoordinate: 0.3,
        pageNumber: 1
    )
    .modelContainer(for: [Project.self, Blueprint.self, LogEntry.self], inMemory: true)
}