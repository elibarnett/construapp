//
//  InteractivePDFView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI
import PDFKit

struct InteractivePDFView: UIViewRepresentable {
    let pdfData: Data
    let blueprint: Blueprint
    @Binding var currentPage: Int
    @Binding var zoomScale: CGFloat
    @Binding var selectedPin: LogEntry?
    @Binding var showingAddLog: Bool
    @Binding var tapLocation: CGPoint
    let selectedCategories: Set<LogCategory>
    @Binding var isSearchMode: Bool
    @Binding var searchArea: CGRect?
    let searchCategories: Set<LogCategory>
    let onCoordinatorReady: ((Coordinator) -> Void)?
    
    private let coordinator = Coordinator()
    
    init(pdfData: Data, blueprint: Blueprint, currentPage: Binding<Int>, zoomScale: Binding<CGFloat>, selectedPin: Binding<LogEntry?>, showingAddLog: Binding<Bool>, tapLocation: Binding<CGPoint>, selectedCategories: Set<LogCategory>, isSearchMode: Binding<Bool>, searchArea: Binding<CGRect?>, searchCategories: Set<LogCategory>, onCoordinatorReady: ((Coordinator) -> Void)? = nil) {
        self.pdfData = pdfData
        self.blueprint = blueprint
        self._currentPage = currentPage
        self._zoomScale = zoomScale
        self._selectedPin = selectedPin
        self._showingAddLog = showingAddLog
        self._tapLocation = tapLocation
        self.selectedCategories = selectedCategories
        self._isSearchMode = isSearchMode
        self._searchArea = searchArea
        self.searchCategories = searchCategories
        self.onCoordinatorReady = onCoordinatorReady
    }
    
    // Add a method to update zoom from external calls
    func updateZoom(to scale: CGFloat) {
        coordinator.updateZoom(to: scale)
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        let pdfView = PDFView()
        
        // Configure PDF view
        pdfView.displayMode = .singlePage
        pdfView.autoScales = false
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.backgroundColor = DesignSystem.Colors.background.uiColor()
        
        // Enable user interaction for zooming and panning
        pdfView.isUserInteractionEnabled = true
        
        // Set up document
        if let document = PDFDocument(data: pdfData) {
            pdfView.document = document
            
            // Navigate to current page
            if let page = document.page(at: currentPage - 1) {
                pdfView.go(to: page)
            }
            
            // Configure scrolling after document is loaded
            DispatchQueue.main.async {
                if let scrollView = pdfView.subviews.first as? UIScrollView {
                    scrollView.delegate = coordinator
                    scrollView.isScrollEnabled = true
                    scrollView.bounces = true
                    scrollView.bouncesZoom = true
                    scrollView.minimumZoomScale = 0.25
                    scrollView.maximumZoomScale = 4.0
                    scrollView.zoomScale = zoomScale
                }
            }
        }
        
        // Set up zoom
        pdfView.minScaleFactor = 0.25
        pdfView.maxScaleFactor = 4.0
        
        // Set initial scale after a brief delay to ensure the document is loaded
        DispatchQueue.main.async {
            pdfView.scaleFactor = zoomScale
        }
        
        // Add PDF view to container
        containerView.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: containerView.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Create pin overlay view
        let pinOverlay = PinOverlayView()
        pinOverlay.backgroundColor = UIColor.clear
        pinOverlay.isUserInteractionEnabled = true // Enable interaction for pin taps
        pinOverlay.blueprint = blueprint
        pinOverlay.currentPage = currentPage
        pinOverlay.selectedCategories = selectedCategories
        pinOverlay.searchArea = searchArea
        pinOverlay.searchCategories = searchCategories
        pinOverlay.isSearchMode = isSearchMode
        pinOverlay.onPinTap = { logEntry in
            selectedPin = logEntry
        }
        
        containerView.addSubview(pinOverlay)
        pinOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pinOverlay.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
            pinOverlay.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
            pinOverlay.topAnchor.constraint(equalTo: pdfView.topAnchor),
            pinOverlay.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor)
        ])
        
        // Create spatial search overlay
        let searchOverlay = SpatialSearchOverlay()
        searchOverlay.backgroundColor = UIColor.clear
        searchOverlay.isSearchMode = isSearchMode
        searchOverlay.searchArea = searchArea
        searchOverlay.onAreaSelected = { rect in
            searchArea = rect
        }
        
        containerView.addSubview(searchOverlay)
        searchOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchOverlay.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
            searchOverlay.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
            searchOverlay.topAnchor.constraint(equalTo: pdfView.topAnchor),
            searchOverlay.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor)
        ])
        
        // Add tap gesture for adding new pins - attach to container for broader coverage
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(coordinator.handleTap(_:)))
        tapGesture.delegate = coordinator
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        // Add to container instead of pdfView for better coverage
        containerView.addGestureRecognizer(tapGesture)
        
        // Store references
        coordinator.pdfView = pdfView
        coordinator.pinOverlay = pinOverlay
        coordinator.searchOverlay = searchOverlay
        coordinator.onTap = { point in
            tapLocation = point
            showingAddLog = true
        }
        
        // Notify parent that coordinator is ready
        onCoordinatorReady?(coordinator)
        
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
                pinOverlay.currentPage = pageIndex + 1
                pinOverlay.setNeedsDisplay()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .PDFViewScaleChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            zoomScale = pdfView.scaleFactor
            pinOverlay.setNeedsDisplay()
        }
        
        return containerView
    }
    
    func updateUIView(_ containerView: UIView, context: Context) {
        guard let pdfView = coordinator.pdfView,
              let pinOverlay = coordinator.pinOverlay,
              let searchOverlay = coordinator.searchOverlay else { return }
        
        // Update current page if changed externally
        if let document = pdfView.document,
           let page = document.page(at: currentPage - 1),
           pdfView.currentPage != page {
            pdfView.go(to: page)
            pinOverlay.currentPage = currentPage
            pinOverlay.setNeedsDisplay()
        }
        
        // Update zoom if changed externally
        if abs(pdfView.scaleFactor - zoomScale) > 0.01 {
            pdfView.scaleFactor = zoomScale
            
            // Also try updating the internal scroll view directly
            if let scrollView = pdfView.subviews.first as? UIScrollView {
                scrollView.setZoomScale(zoomScale, animated: true)
            }
        }
        
        // Update categories and redraw pins
        pinOverlay.selectedCategories = selectedCategories
        pinOverlay.searchArea = searchArea
        pinOverlay.searchCategories = searchCategories
        pinOverlay.isSearchMode = isSearchMode
        pinOverlay.setNeedsDisplay()
        
        // Update search overlay
        searchOverlay.isSearchMode = isSearchMode
        searchOverlay.searchArea = searchArea
    }
    
    static func dismantleUIView(_ containerView: UIView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
    }
    
    func makeCoordinator() -> Coordinator {
        coordinator
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate, UIScrollViewDelegate {
        var pdfView: PDFView?
        var pinOverlay: PinOverlayView?
        var searchOverlay: SpatialSearchOverlay?
        var onTap: ((CGPoint) -> Void)?
        
        func updateZoom(to scale: CGFloat) {
            guard let pdfView = pdfView else { return }
            
            // Get the scroll view and current center point before zoom
            guard let scrollView = pdfView.subviews.first as? UIScrollView else {
                pdfView.scaleFactor = scale
                return
            }
            
            // Store current zoom level
            let currentScale = pdfView.scaleFactor
            
            // Get current visible center in scroll view content coordinates
            let visibleRect = scrollView.bounds
            let contentOffset = scrollView.contentOffset
            let centerX = contentOffset.x + visibleRect.width / 2
            let centerY = contentOffset.y + visibleRect.height / 2
            
            // Apply new scale factor
            pdfView.scaleFactor = scale
            
            // Wait for the scale change to take effect
            DispatchQueue.main.async {
                // Calculate the scale ratio
                let scaleRatio = scale / currentScale
                
                // Calculate where the center point should be now
                let newCenterX = centerX * scaleRatio
                let newCenterY = centerY * scaleRatio
                
                // Calculate new offset to maintain center
                let newOffsetX = newCenterX - visibleRect.width / 2
                let newOffsetY = newCenterY - visibleRect.height / 2
                
                // Get updated content size after zoom
                let contentSize = scrollView.contentSize
                let maxOffsetX = max(0, contentSize.width - visibleRect.width)
                let maxOffsetY = max(0, contentSize.height - visibleRect.height)
                
                // Clamp the offset
                let clampedOffset = CGPoint(
                    x: max(0, min(maxOffsetX, newOffsetX)),
                    y: max(0, min(maxOffsetY, newOffsetY))
                )
                
                // Apply the offset
                scrollView.contentOffset = clampedOffset
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let pdfView = pdfView,
                  let currentPage = pdfView.currentPage else { 
                return 
            }
            
            // Get tap location in the gesture recognizer's view (container view)
            let containerPoint = gesture.location(in: gesture.view)
            
            // Convert to PDFView coordinates
            let pdfViewPoint = gesture.view?.convert(containerPoint, to: pdfView) ?? containerPoint
            
            // Check if the point is within PDFView bounds
            guard pdfView.bounds.contains(pdfViewPoint) else {
                return
            }
            
            // Convert the tap point to PDF page coordinates
            let pdfPoint = pdfView.convert(pdfViewPoint, to: currentPage)
            
            // Get the PDF page bounds to normalize coordinates
            let pageBounds = currentPage.bounds(for: .mediaBox)
            
            // Check if point is within page bounds
            guard pageBounds.contains(pdfPoint) else {
                return
            }
            
            // Convert to normalized coordinates (0-1)
            // PDF coordinate system has origin at bottom-left, we want top-left
            let normalizedPoint = CGPoint(
                x: pdfPoint.x / pageBounds.width,
                y: (pageBounds.height - pdfPoint.y) / pageBounds.height
            )
            
            // Clamp to valid range
            let clampedPoint = CGPoint(
                x: max(0, min(1, normalizedPoint.x)),
                y: max(0, min(1, normalizedPoint.y))
            )
            
            onTap?(clampedPoint)
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            // Only handle tap gestures, and only if not handled by overlays
            guard gestureRecognizer is UITapGestureRecognizer else { return false }
            
            // Check if pin overlay should handle this touch (if it's on a pin)
            if let pinOverlay = pinOverlay,
               let hitView = pinOverlay.hitTest(touch.location(in: pinOverlay), with: nil),
               hitView == pinOverlay {
                return false // Let pin overlay handle it
            }
            
            // Check if search overlay should handle this touch (if in search mode)
            if let searchOverlay = searchOverlay,
               searchOverlay.isSearchMode,
               let hitView = searchOverlay.hitTest(touch.location(in: searchOverlay), with: nil),
               hitView == searchOverlay {
                return false // Let search overlay handle it
            }
            
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Don't recognize simultaneously with other tap gestures to avoid conflicts
            if otherGestureRecognizer is UITapGestureRecognizer {
                return false
            }
            // Allow with zoom and pan gestures
            return true
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // Always allow our tap gesture to begin
            return gestureRecognizer is UITapGestureRecognizer
        }
        
        // MARK: - UIScrollViewDelegate
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            // Return the first subview of the scroll view (usually the document view)
            return scrollView.subviews.first
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Update pin overlay display when zoom changes
            pinOverlay?.setNeedsDisplay()
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            // Zoom gesture completed
        }
    }
}