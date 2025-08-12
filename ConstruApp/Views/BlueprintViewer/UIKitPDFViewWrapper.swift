//
//  UIKitPDFViewWrapper.swift
//  ConstruApp
//
//  Created by Claude on 8/5/25.
//

import SwiftUI
import UIKit
import PDFKit

struct UIKitPDFViewWrapper: UIViewControllerRepresentable {
    let blueprint: Blueprint
    @Binding var currentPage: Int
    @Binding var zoomScale: CGFloat
    @Binding var selectedPin: LogEntry?
    let selectedCategories: Set<LogCategory>
    let onTapForNewPin: (CGPoint, Int) -> Void
    
    // Spatial search parameters
    let isSearchMode: Bool
    let searchArea: CGRect?
    let onSpatialAreaSelected: (CGRect) -> Void
    
    func makeUIViewController(context: Context) -> UIKitPDFViewController {
        let controller = UIKitPDFViewController(
            blueprint: blueprint,
            currentPage: currentPage,
            selectedCategories: selectedCategories
        )
        
        // Set up callbacks
        controller.onPinTap = { logEntry in
            selectedPin = logEntry
        }
        
        controller.onTapForNewPin = { point, page in
            print("DEBUG: UIKitPDFViewWrapper - received coordinates: \(point)")
            
            // Use direct callback to parent view
            DispatchQueue.main.async {
                print("DEBUG: UIKitPDFViewWrapper - calling parent callback with coordinates: \(point)")
                onTapForNewPin(point, page)
            }
        }
        
        controller.onZoomChanged = { scale in
            if abs(zoomScale - scale) > 0.01 {
                zoomScale = scale
            }
        }
        
        controller.onPageChanged = { page in
            if currentPage != page {
                currentPage = page
            }
        }
        
        controller.onSpatialAreaSelected = { area in
            onSpatialAreaSelected(area)
        }
        
        return controller
    }
    
    func updateUIViewController(_ controller: UIKitPDFViewController, context: Context) {
        // Update categories if changed
        controller.updateCategories(selectedCategories)
        
        // Update page if changed externally
        if controller.view.subviews.first is PDFView {
            if currentPage != controller.currentPage {
                controller.goToPage(currentPage)
            }
        }
        
        // Update zoom if changed externally (avoid recursive updates)
        if let pdfView = controller.view.subviews.first as? PDFView,
           abs(pdfView.scaleFactor - zoomScale) > 0.01 {
            controller.zoomToScale(zoomScale, animated: true)
        }
        
        // Update spatial search mode and area
        controller.setSpatialSearchMode(isSearchMode)
        controller.setSpatialSearchArea(searchArea)
    }
}

#Preview {
    @Previewable @State var currentPage = 1
    @Previewable @State var zoomScale: CGFloat = 1.0
    @Previewable @State var selectedPin: LogEntry?
    
    let blueprint = Blueprint(
        name: "Sample Blueprint",
        fileName: "sample.pdf",
        pdfData: Data(),
        pageCount: 1,
        pdfWidth: 612,
        pdfHeight: 792
    )
    
    UIKitPDFViewWrapper(
        blueprint: blueprint,
        currentPage: $currentPage,
        zoomScale: $zoomScale,
        selectedPin: $selectedPin,
        selectedCategories: Set(LogCategory.allCases),
        onTapForNewPin: { point, page in
            print("Preview tap: \(point)")
        },
        isSearchMode: false,
        searchArea: nil,
        onSpatialAreaSelected: { area in
            print("Preview spatial area selected: \(area)")
        }
    )
}