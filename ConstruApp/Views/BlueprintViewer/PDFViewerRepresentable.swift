//
//  PDFViewerRepresentable.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import PDFKit

struct PDFViewerRepresentable: UIViewRepresentable {
    let pdfData: Data
    let blueprint: Blueprint
    @Binding var currentPage: Int
    @Binding var zoomScale: CGFloat
    @State private var pdfView: PDFView?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configure PDF view
        pdfView.displayMode = .singlePage
        pdfView.autoScales = false
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.backgroundColor = DesignSystem.Colors.background.uiColor()
        
        // Set up document
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
            
            // Navigate to current page
            if let page = document.page(at: currentPage - 1) {
                pdfView.go(to: page)
            }
        }
        
        // Set up zoom
        pdfView.minScaleFactor = 0.25
        pdfView.maxScaleFactor = 4.0
        pdfView.scaleFactor = zoomScale
        
        // Set up notifications
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            if let currentPDFPage = pdfView.currentPage,
               let document = pdfView.document {
                let pageIndex = document.index(for: currentPDFPage)
                currentPage = pageIndex + 1
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .PDFViewScaleChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            zoomScale = pdfView.scaleFactor
        }
        
        self.pdfView = pdfView
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update current page if changed externally
        if let document = pdfView.document,
           let page = document.page(at: currentPage - 1),
           pdfView.currentPage != page {
            pdfView.go(to: page)
        }
        
        // Update zoom if changed externally
        if abs(pdfView.scaleFactor - zoomScale) > 0.01 {
            pdfView.scaleFactor = zoomScale
        }
    }
    
    static func dismantleUIView(_ pdfView: PDFView, coordinator: ()) {
        NotificationCenter.default.removeObserver(pdfView)
    }
}

// Color extension is defined in DesignSystem.swift