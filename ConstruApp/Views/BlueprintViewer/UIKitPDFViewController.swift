//
//  UIKitPDFViewController.swift
//  ConstruApp
//
//  Created by Claude on 8/5/25.
//

import UIKit
import PDFKit
import SwiftUI

class UIKitPDFViewController: UIViewController {
    
    // MARK: - Properties
    private var pdfView: PDFView!
    private var pinOverlayView: PinOverlayView!
    private var spatialSearchOverlay: SpatialSearchOverlay!
    private var blueprint: Blueprint
    private(set) var currentPage: Int
    private var selectedCategories: Set<LogCategory>
    private var isFirstTap = true
    
    // Callbacks to SwiftUI
    var onPinTap: ((LogEntry) -> Void)?
    var onTapForNewPin: ((CGPoint, Int) -> Void)?
    var onZoomChanged: ((CGFloat) -> Void)?
    var onPageChanged: ((Int) -> Void)?
    var onSpatialAreaSelected: ((CGRect) -> Void)?
    
    // MARK: - Initialization
    init(blueprint: Blueprint, currentPage: Int, selectedCategories: Set<LogCategory>) {
        self.blueprint = blueprint
        self.currentPage = currentPage
        self.selectedCategories = selectedCategories
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDFView()
        setupPinOverlay()
        setupSpatialSearchOverlay()
        setupGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ensure PDF is fully loaded after view appears
        ensurePDFLoaded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Update spatial overlay bounds after layout
        print("DEBUG: viewDidLayoutSubviews - spatialSearchOverlay bounds: \(spatialSearchOverlay.bounds)")
        print("DEBUG: viewDidLayoutSubviews - pdfView bounds: \(pdfView.bounds)")
    }
    
    // MARK: - Setup Methods
    private func setupPDFView() {
        pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure PDF view for optimal zoom/pan behavior
        pdfView.displayMode = .singlePage
        pdfView.autoScales = false
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)
        pdfView.backgroundColor = UIColor.systemBackground
        
        // Enable user interaction
        pdfView.isUserInteractionEnabled = true
        
        // Set zoom limits
        pdfView.minScaleFactor = 0.25
        pdfView.maxScaleFactor = 4.0
        
        // Load PDF document
        if let document = PDFDocument(data: blueprint.pdfData) {
            pdfView.document = document
            if let page = document.page(at: currentPage - 1) {
                pdfView.go(to: page)
            }
        }
        
        // Add to view hierarchy
        view.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Configure scroll view delegate for zoom handling
        if let scrollView = pdfView.subviews.first as? UIScrollView {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.25
            scrollView.maximumZoomScale = 4.0
        }
        
        // Set up notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pdfViewPageChanged),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pdfViewScaleChanged),
            name: .PDFViewScaleChanged,
            object: pdfView
        )
    }
    
    private func setupPinOverlay() {
        pinOverlayView = PinOverlayView()
        pinOverlayView.translatesAutoresizingMaskIntoConstraints = false
        pinOverlayView.backgroundColor = UIColor.clear
        pinOverlayView.isUserInteractionEnabled = true
        
        // Configure pin overlay
        pinOverlayView.blueprint = blueprint
        pinOverlayView.currentPage = currentPage
        pinOverlayView.selectedCategories = selectedCategories
        pinOverlayView.onPinTap = onPinTap
        
        // Add as overlay - constrain to the PDF view so it moves with content
        view.addSubview(pinOverlayView)
        NSLayoutConstraint.activate([
            pinOverlayView.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
            pinOverlayView.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
            pinOverlayView.topAnchor.constraint(equalTo: pdfView.topAnchor),
            pinOverlayView.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor)
        ])
        
        // Set up scroll view delegate to track content movements
        if let scrollView = pdfView.subviews.first as? UIScrollView {
            scrollView.delegate = self
        }
    }
    
    private func setupSpatialSearchOverlay() {
        spatialSearchOverlay = SpatialSearchOverlay()
        spatialSearchOverlay.translatesAutoresizingMaskIntoConstraints = false
        spatialSearchOverlay.backgroundColor = UIColor.clear
        spatialSearchOverlay.isUserInteractionEnabled = true // Always enabled for touch detection
        
        // Configure callback
        spatialSearchOverlay.onAreaSelected = { [weak self] normalizedRect in
            print("DEBUG: spatialSearchOverlay callback triggered with area: \(normalizedRect)")
            self?.onSpatialAreaSelected?(normalizedRect)
        }
        
        // Add as top-most overlay - above everything else
        view.addSubview(spatialSearchOverlay)
        NSLayoutConstraint.activate([
            spatialSearchOverlay.leadingAnchor.constraint(equalTo: pdfView.leadingAnchor),
            spatialSearchOverlay.trailingAnchor.constraint(equalTo: pdfView.trailingAnchor),
            spatialSearchOverlay.topAnchor.constraint(equalTo: pdfView.topAnchor),
            spatialSearchOverlay.bottomAnchor.constraint(equalTo: pdfView.bottomAnchor)
        ])
        
        print("DEBUG: spatialSearchOverlay setup complete - bounds: \(spatialSearchOverlay.bounds)")
    }
    
    private func setupGestures() {
        // Add tap gesture for creating new pins
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Public Methods
    func updateCategories(_ categories: Set<LogCategory>) {
        selectedCategories = categories
        pinOverlayView.selectedCategories = categories
        pinOverlayView.setNeedsDisplay()
    }
    
    func zoomToScale(_ scale: CGFloat, animated: Bool = true) {
        guard let scrollView = pdfView.subviews.first as? UIScrollView else { return }
        
        // Get current center point
        let visibleRect = scrollView.bounds
        let centerX = scrollView.contentOffset.x + visibleRect.width / 2
        let centerY = scrollView.contentOffset.y + visibleRect.height / 2
        
        // Apply zoom
        if animated {
            UIView.animate(withDuration: 0.3) {
                scrollView.zoomScale = scale
                
                // Recalculate offset to maintain center
                let newCenterX = centerX * (scale / scrollView.zoomScale)
                let newCenterY = centerY * (scale / scrollView.zoomScale)
                
                let newOffsetX = newCenterX - visibleRect.width / 2
                let newOffsetY = newCenterY - visibleRect.height / 2
                
                scrollView.contentOffset = CGPoint(
                    x: max(0, min(scrollView.contentSize.width - visibleRect.width, newOffsetX)),
                    y: max(0, min(scrollView.contentSize.height - visibleRect.height, newOffsetY))
                )
            }
        } else {
            scrollView.zoomScale = scale
        }
    }
    
    func goToPage(_ page: Int) {
        guard let document = pdfView.document,
              let pdfPage = document.page(at: page - 1) else { return }
        
        pdfView.go(to: pdfPage)
        currentPage = page
        pinOverlayView.currentPage = page
        pinOverlayView.setNeedsDisplay()
    }
    
    func setSpatialSearchMode(_ enabled: Bool) {
        spatialSearchOverlay.isSearchMode = enabled
        
        // Enable/disable scroll view interaction based on search mode
        if let scrollView = pdfView.subviews.first as? UIScrollView {
            scrollView.isScrollEnabled = !enabled
            scrollView.panGestureRecognizer.isEnabled = !enabled
            scrollView.pinchGestureRecognizer?.isEnabled = !enabled
        }
        
        // Ensure overlay has proper bounds when search mode is enabled
        if enabled {
            view.layoutIfNeeded() // Force layout update
            print("DEBUG: setSpatialSearchMode - overlay bounds after layout: \(spatialSearchOverlay.bounds)")
            print("DEBUG: setSpatialSearchMode - pdfView bounds: \(pdfView.bounds)")
        }
        
        print("DEBUG: setSpatialSearchMode - spatial search \(enabled ? "enabled" : "disabled")")
        print("DEBUG: setSpatialSearchMode - PDF scroll gestures \(enabled ? "disabled" : "enabled")")
    }
    
    func setSpatialSearchArea(_ area: CGRect?) {
        spatialSearchOverlay.searchArea = area
        print("DEBUG: setSpatialSearchArea - area: \(area?.debugDescription ?? "nil")")
    }
    
    private func ensurePDFLoaded() {
        // Give the PDF view a moment to fully initialize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let document = self.pdfView.document,
               let page = document.page(at: self.currentPage - 1) {
                self.pdfView.go(to: page)
                print("DEBUG: ensurePDFLoaded - PDF reloaded successfully")
            }
        }
    }

    // MARK: - Gesture Handlers
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapCountInfo = isFirstTap ? "FIRST TAP" : "subsequent tap"
        print("DEBUG: handleTap - \(tapCountInfo) detected")
        
        guard let currentPDFPage = pdfView.currentPage else { 
            print("DEBUG: handleTap - currentPDFPage is nil (\(tapCountInfo)), attempting fallback")
            
            // First, try immediate fallback
            if let document = pdfView.document,
               currentPage > 0 && currentPage <= document.pageCount,
               let page = document.page(at: currentPage - 1) {
                handleTapWithPage(gesture, page: page)
                isFirstTap = false
                return
            }
            
            // If immediate fallback fails, try delayed retry (for initial load)
            print("DEBUG: handleTap - immediate fallback failed (\(tapCountInfo)), trying delayed retry")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let document = self.pdfView.document,
                   self.currentPage > 0 && self.currentPage <= document.pageCount,
                   let page = document.page(at: self.currentPage - 1) {
                    // Retry the tap handling with the loaded page
                    self.handleTapWithPage(gesture, page: page)
                    print("DEBUG: handleTap - delayed retry successful (\(tapCountInfo))")
                    self.isFirstTap = false
                } else {
                    print("DEBUG: handleTap - delayed retry also failed (\(tapCountInfo))")
                }
            }
            return 
        }
        
        print("DEBUG: handleTap - currentPDFPage available (\(tapCountInfo)), proceeding normally")
        handleTapWithPage(gesture, page: currentPDFPage)
        isFirstTap = false
    }
    
    private func handleTapWithPage(_ gesture: UITapGestureRecognizer, page: PDFPage) {
        let tapPoint = gesture.location(in: pdfView)
        print("DEBUG: handleTap - tapPoint: \(tapPoint)")
        
        // Convert tap point to PDF coordinates
        let pdfPoint = pdfView.convert(tapPoint, to: page)
        let pageBounds = page.bounds(for: .mediaBox)
        print("DEBUG: handleTap - pdfPoint: \(pdfPoint), pageBounds: \(pageBounds)")
        
        // Ensure page bounds are valid
        guard pageBounds.width > 0 && pageBounds.height > 0 else {
            print("DEBUG: handleTap - invalid page bounds")
            return
        }
        
        // Normalize coordinates (0-1) with Y-axis flip
        let normalizedPoint = CGPoint(
            x: pdfPoint.x / pageBounds.width,
            y: (pageBounds.height - pdfPoint.y) / pageBounds.height
        )
        
        // Clamp to valid range
        let clampedPoint = CGPoint(
            x: max(0, min(1, normalizedPoint.x)),
            y: max(0, min(1, normalizedPoint.y))
        )
        
        print("DEBUG: handleTap - normalizedPoint: \(normalizedPoint), clampedPoint: \(clampedPoint)")
        
        onTapForNewPin?(clampedPoint, currentPage)
    }
    
    // MARK: - Notification Handlers
    @objc private func pdfViewPageChanged() {
        guard let document = pdfView.document,
              let currentPDFPage = pdfView.currentPage else { return }
        
        let pageIndex = document.index(for: currentPDFPage)
        currentPage = pageIndex + 1
        pinOverlayView.currentPage = currentPage
        pinOverlayView.setNeedsDisplay()
        onPageChanged?(currentPage)
    }
    
    @objc private func pdfViewScaleChanged() {
        onZoomChanged?(pdfView.scaleFactor)
        pinOverlayView.setNeedsDisplay()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UIScrollViewDelegate
extension UIKitPDFViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews.first
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        pinOverlayView.setNeedsDisplay()
        onZoomChanged?(scrollView.zoomScale)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Update pin overlay when content scrolls/pans
        pinOverlayView.setNeedsDisplay()
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // Zoom gesture completed
        pinOverlayView.setNeedsDisplay()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // Scrolling animation completed
        pinOverlayView.setNeedsDisplay()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Scrolling deceleration completed
        pinOverlayView.setNeedsDisplay()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension UIKitPDFViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // If spatial search mode is active, don't handle taps for new pins
        if spatialSearchOverlay.isSearchMode {
            print("DEBUG: gestureRecognizer shouldReceive - rejecting touch due to search mode")
            return false // Let spatial search overlay handle all touches
        }
        
        // Only handle taps that are not on existing pins
        let point = touch.location(in: pinOverlayView)
        
        // Check if touch is on a pin
        if let hitView = pinOverlayView.hitTest(point, with: nil), hitView == pinOverlayView {
            return false // Let pin overlay handle it
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow simultaneous recognition with scroll view gestures
        return !(otherGestureRecognizer is UITapGestureRecognizer)
    }
}