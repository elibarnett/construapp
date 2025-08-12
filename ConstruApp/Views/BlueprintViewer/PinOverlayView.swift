//
//  PinOverlayView.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import UIKit
import SwiftUI
import PDFKit

class PinOverlayView: UIView {
    var blueprint: Blueprint?
    var currentPage: Int = 1
    var selectedCategories: Set<LogCategory> = Set(LogCategory.allCases)
    var onPinTap: ((LogEntry) -> Void)?
    
    // Spatial Search Properties
    var isSearchMode: Bool = false
    var searchArea: CGRect?
    var searchCategories: Set<LogCategory> = Set(LogCategory.allCases)
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Only intercept touches that are on actual pins
        guard let blueprint = blueprint else {
            return nil
        }
        
        let logEntries = blueprint.logEntriesOnPage(currentPage).filter { selectedCategories.contains($0.category) }
        let pinSize: CGFloat = 30
        
        for logEntry in logEntries {
            let pinPoint = convertLogEntryToViewCoordinates(logEntry)
            let pinRect = CGRect(
                x: pinPoint.x - pinSize/2,
                y: pinPoint.y - pinSize/2,
                width: pinSize,
                height: pinSize
            )
            
            if pinRect.contains(point) {
                return self
            }
        }
        
        // If not on a pin, let touches pass through
        return nil
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let blueprint = blueprint else { return }
        
        let point = touch.location(in: self)
        let logEntries = blueprint.logEntriesOnPage(currentPage).filter { selectedCategories.contains($0.category) }
        let pinSize: CGFloat = 30
        
        for logEntry in logEntries {
            let pinPoint = convertLogEntryToViewCoordinates(logEntry)
            let pinRect = CGRect(
                x: pinPoint.x - pinSize/2,
                y: pinPoint.y - pinSize/2,
                width: pinSize,
                height: pinSize
            )
            
            if pinRect.contains(point) {
                onPinTap?(logEntry)
                return
            }
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let blueprint = blueprint,
              let context = UIGraphicsGetCurrentContext() else { return }
        
        let logEntries = blueprint.logEntriesOnPage(currentPage).filter { selectedCategories.contains($0.category) }
        
        for logEntry in logEntries {
            drawPin(for: logEntry, in: context)
        }
    }
    
    private func drawPin(for logEntry: LogEntry, in context: CGContext) {
        let pinPoint = convertLogEntryToViewCoordinates(logEntry)
        let pinSize: CGFloat = 24
        let pinRadius = pinSize / 2
        
        // Determine if pin should be dimmed during search mode
        let isDimmed = isSearchMode && shouldDimPin(logEntry)
        let alpha: CGFloat = isDimmed ? 0.3 : 1.0
        
        // Draw pin shadow
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.3 * alpha).cgColor)
        
        // Draw pin background
        let pinRect = CGRect(
            x: pinPoint.x - pinRadius,
            y: pinPoint.y - pinRadius,
            width: pinSize,
            height: pinSize
        )
        
        context.setFillColor(logEntry.category.color.uiColor().withAlphaComponent(alpha).cgColor)
        context.fillEllipse(in: pinRect)
        
        // Draw pin border
        context.setStrokeColor(UIColor.white.withAlphaComponent(alpha).cgColor)
        context.setLineWidth(2)
        context.strokeEllipse(in: pinRect)
        
        context.restoreGState()
        
        // Draw category icon
        drawCategoryIcon(for: logEntry.category, at: pinPoint, size: pinSize * 0.6, alpha: alpha)
        
        // Draw pulse animation for recently added pins
        if isRecentlyAdded(logEntry) {
            drawPulseAnimation(at: pinPoint, radius: pinRadius, alpha: alpha)
        }
        
        // Draw highlight ring for pins within search area
        if isSearchMode && !isDimmed && searchArea != nil {
            drawHighlightRing(at: pinPoint, radius: pinRadius)
        }
    }
    
    private func drawCategoryIcon(for category: LogCategory, at point: CGPoint, size: CGFloat, alpha: CGFloat = 1.0) {
        let iconRect = CGRect(
            x: point.x - size/2,
            y: point.y - size/2,
            width: size,
            height: size
        )
        
        // Get system image for category
        guard let image = UIImage(systemName: category.iconName) else { return }
        
        // Configure image
        let configuration = UIImage.SymbolConfiguration(pointSize: size * 0.7, weight: .medium)
        let configuredImage = image.withConfiguration(configuration)
        
        // Draw image in white with alpha
        configuredImage.withTintColor(UIColor.white.withAlphaComponent(alpha), renderingMode: .alwaysOriginal)
            .draw(in: iconRect)
    }
    
    private func drawPulseAnimation(at point: CGPoint, radius: CGFloat, alpha: CGFloat = 1.0) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Create pulse effect
        let pulseRadius = radius * 1.5
        let pulseRect = CGRect(
            x: point.x - pulseRadius,
            y: point.y - pulseRadius,
            width: pulseRadius * 2,
            height: pulseRadius * 2
        )
        
        context.setStrokeColor(DesignSystem.Colors.primary.uiColor().withAlphaComponent(0.3 * alpha).cgColor)
        context.setLineWidth(2)
        context.strokeEllipse(in: pulseRect)
    }
    
    private func isRecentlyAdded(_ logEntry: LogEntry) -> Bool {
        // Consider entries added in the last 10 seconds as recently added
        return Date().timeIntervalSince(logEntry.date) < 10
    }
    
    private func shouldDimPin(_ logEntry: LogEntry) -> Bool {
        guard let searchArea = searchArea else { return false }
        
        // Check if pin is outside search categories
        if !searchCategories.contains(logEntry.category) {
            return true
        }
        
        // Check if pin is outside search area
        let entryPoint = CGPoint(x: logEntry.xCoordinate, y: logEntry.yCoordinate)
        return !searchArea.contains(entryPoint)
    }
    
    private func drawHighlightRing(at point: CGPoint, radius: CGFloat) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Create highlight ring around matching pins
        let ringRadius = radius * 1.3
        let ringRect = CGRect(
            x: point.x - ringRadius,
            y: point.y - ringRadius,
            width: ringRadius * 2,
            height: ringRadius * 2
        )
        
        context.setStrokeColor(DesignSystem.Colors.accent.uiColor().cgColor)
        context.setLineWidth(3)
        context.strokeEllipse(in: ringRect)
        
        // Add inner glow effect
        context.setStrokeColor(DesignSystem.Colors.accent.uiColor().withAlphaComponent(0.3).cgColor)
        context.setLineWidth(6)
        context.strokeEllipse(in: ringRect)
    }
    
    func convertLogEntryToViewCoordinates(_ logEntry: LogEntry) -> CGPoint {        
        // Get the PDF content area within the view
        guard let pdfView = getPDFView(),
              let currentPage = pdfView.currentPage else {
            // Fallback to simple bounds conversion
            return CGPoint(
                x: logEntry.xCoordinate * bounds.width,
                y: logEntry.yCoordinate * bounds.height
            )
        }
        
        // Get the PDF page bounds
        let pageBounds = currentPage.bounds(for: .mediaBox)
        
        // Convert normalized coordinates to PDF page coordinates
        let pdfPoint = CGPoint(
            x: logEntry.xCoordinate * pageBounds.width,
            y: pageBounds.height * (1.0 - logEntry.yCoordinate) // Flip Y coordinate
        )
        
        // Convert PDF coordinates to view coordinates within the PDFView
        let viewPoint = pdfView.convert(pdfPoint, from: currentPage)
        
        // Since the overlay is constrained to the PDFView, we can directly use the PDFView coordinates
        // but we need to account for the coordinate system difference
        return viewPoint
    }
    
    func convertViewToNormalizedCoordinates(_ point: CGPoint) -> CGPoint {
        // Get the PDF content area within the view
        guard let pdfView = getPDFView(),
              let currentPage = pdfView.currentPage else {
            // Fallback to simple bounds conversion
            return CGPoint(
                x: point.x / bounds.width,
                y: point.y / bounds.height
            )
        }
        
        // Convert overlay coordinates to PDFView coordinates
        let pdfViewPoint = convert(point, to: pdfView)
        
        // Convert view coordinates to PDF page coordinates
        let pdfPoint = pdfView.convert(pdfViewPoint, to: currentPage)
        
        // Get the PDF page bounds to normalize coordinates
        let pageBounds = currentPage.bounds(for: .mediaBox)
        
        // Convert to normalized coordinates (0-1)
        let normalizedPoint = CGPoint(
            x: pdfPoint.x / pageBounds.width,
            y: (pageBounds.height - pdfPoint.y) / pageBounds.height // Flip Y coordinate
        )
        
        // Clamp to valid range
        return CGPoint(
            x: max(0, min(1, normalizedPoint.x)),
            y: max(0, min(1, normalizedPoint.y))
        )
    }
    
    private func getPDFView() -> PDFView? {
        // Walk up the view hierarchy to find the PDFView
        var currentView: UIView? = superview
        while let view = currentView {
            if let pdfView = view as? PDFView {
                return pdfView
            }
            // Check subviews for PDFView
            for subview in view.subviews {
                if let pdfView = subview as? PDFView {
                    return pdfView
                }
            }
            currentView = view.superview
        }
        return nil
    }
}

// MARK: - LogCategory Color Extension
extension LogCategory {
    var color: Color {
        switch self {
        case .electrical:
            return DesignSystem.Colors.electrical
        case .plumbing:
            return DesignSystem.Colors.plumbing
        case .structural:
            return DesignSystem.Colors.structural
        case .hvac:
            return DesignSystem.Colors.hvac
        case .insulation:
            return DesignSystem.Colors.insulation
        case .flooring:
            return DesignSystem.Colors.flooring
        case .roofing:
            return DesignSystem.Colors.roofing
        case .windows:
            return DesignSystem.Colors.windows
        case .doors:
            return DesignSystem.Colors.doors
        case .finishes:
            return DesignSystem.Colors.finishes
        case .safety:
            return DesignSystem.Colors.safety
        case .general:
            return DesignSystem.Colors.general
        }
    }
}