//
//  MediaPickerView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI

struct MediaPickerView: View {
    @Binding var isPresented: Bool
    let onPhotosSelected: ([Data]) -> Void
    let onVideoCapture: (Data, String) -> Void
    
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.xl) {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text(NSLocalizedString("media.add_media", comment: ""))
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(NSLocalizedString("media.capture_document", comment: ""))
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Camera Button
                    Button(action: { showingCamera = true }) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "camera")
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("media.take_photo_video", comment: ""))
                                    .font(DesignSystem.Typography.bodyMedium)
                                Text(NSLocalizedString("media.use_camera", comment: ""))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(DesignSystem.Spacing.md)
                        .cardStyle()
                    }
                    
                    // Photo Library Button
                    Button(action: { showingPhotoLibrary = true }) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(NSLocalizedString("media.choose_library", comment: ""))
                                    .font(DesignSystem.Typography.bodyMedium)
                                Text(NSLocalizedString("media.select_photos", comment: ""))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(DesignSystem.Spacing.md)
                        .cardStyle()
                    }
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.screenPadding)
            .navigationTitle(NSLocalizedString("media.add_media", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .background(DesignSystem.Colors.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("general.done", comment: "")) {
                        isPresented = false
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(
                isPresented: $showingCamera,
                onPhotoCapture: { data in
                    onPhotosSelected([data]) // Convert single photo to array
                    isPresented = false
                },
                onVideoCapture: { data, fileName in
                    onVideoCapture(data, fileName)
                    isPresented = false
                }
            )
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryView(
                isPresented: $showingPhotoLibrary,
                onPhotosSelected: { photoDataArray in
                    onPhotosSelected(photoDataArray)
                    isPresented = false
                }
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
}

#Preview {
    MediaPickerView(
        isPresented: .constant(true),
        onPhotosSelected: { _ in },
        onVideoCapture: { _, _ in }
    )
}