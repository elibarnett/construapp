//
//  CameraView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onPhotoCapture: (Data) -> Void
    let onVideoCapture: (Data, String) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 300 // 5 minutes max
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[.originalImage] as? UIImage {
                // Handle photo capture
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    parent.onPhotoCapture(imageData)
                }
            } else if let videoURL = info[.mediaURL] as? URL {
                // Handle video capture
                do {
                    let videoData = try Data(contentsOf: videoURL)
                    let fileName = "video_\(Date().timeIntervalSince1970).mov"
                    parent.onVideoCapture(videoData, fileName)
                } catch {
                    print("Error reading video data: \(error)")
                }
            }
            
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

struct PhotoLibraryView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onPhotosSelected: ([Data]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // 0 means no limit
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryView
        
        init(_ parent: PhotoLibraryView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard !results.isEmpty else { return }
            
            var imageDataArray: [Data] = []
            let group = DispatchGroup()
            
            for result in results {
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                    defer { group.leave() }
                    
                    if let image = object as? UIImage,
                       let imageData = image.jpegData(compressionQuality: 0.8) {
                        DispatchQueue.main.async {
                            imageDataArray.append(imageData)
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.parent.onPhotosSelected(imageDataArray)
            }
        }
    }
}