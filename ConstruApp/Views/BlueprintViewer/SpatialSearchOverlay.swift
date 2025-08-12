//
//  SpatialSearchOverlay.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI

class SpatialSearchOverlay: UIView {
    var isSearchMode: Bool = false {
        didSet {
            print("🔍 DEBUG: SpatialSearchOverlay isSearchMode changed to: \(isSearchMode)")
            print("🔍 DEBUG: SpatialSearchOverlay isUserInteractionEnabled: \(isUserInteractionEnabled)")
            setNeedsDisplay()
        }
    }
    
    var searchArea: CGRect? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var onAreaSelected: ((CGRect) -> Void)?
    
    private var startPoint: CGPoint?
    private var currentRect: CGRect?
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = true
        
        // Add pan gesture recognizer for drag-to-select
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if isSearchMode {
            // Draw subtle overlay with animated pulse
            let overlayColor = UIColor.systemBlue.withAlphaComponent(0.08)
            context.setFillColor(overlayColor.cgColor)
            context.fill(bounds)
            
            // Draw selection rectangle if exists
            if let searchRect = searchArea {
                drawSelectionRect(searchRect, in: context, isActive: true)
            } else if let currentRect = currentRect {
                drawSelectionRect(currentRect, in: context, isActive: false)
            }
            
            // Draw crosshair guides for precise selection
            if currentRect == nil && searchArea == nil {
                drawSelectionGuides(in: context)
            }
        }
    }
    
    private func drawSelectionRect(_ rect: CGRect, in context: CGContext, isActive: Bool) {
        // Clear the selected area to make it fully visible
        context.setBlendMode(.clear)
        context.fill(rect)
        context.setBlendMode(.normal)
        
        // Draw animated border with rounded corners
        let cornerRadius: CGFloat = 8
        let borderPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        
        context.setStrokeColor(isActive ? 
            UIColor.systemOrange.cgColor : 
            UIColor.systemBlue.cgColor)
        context.setLineWidth(isActive ? 3 : 2)
        context.setLineDash(phase: 0, lengths: isActive ? [] : [8, 4])
        context.addPath(borderPath.cgPath)
        context.strokePath()
        
        // Draw corner handles for active selection
        if isActive {
            drawCornerHandles(for: rect, in: context)
        }
    }
    
    private func drawCornerHandles(for rect: CGRect, in context: CGContext) {
        let handleSize: CGFloat = 12
        let handleColor = UIColor.systemOrange.cgColor
        
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(handleColor)
        context.setLineWidth(2)
        
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        
        for corner in corners {
            let handleRect = CGRect(
                x: corner.x - handleSize/2,
                y: corner.y - handleSize/2,
                width: handleSize,
                height: handleSize
            )
            context.fillEllipse(in: handleRect)
            context.strokeEllipse(in: handleRect)
        }
    }
    
    private func drawSelectionGuides(in context: CGContext) {
        // Draw subtle crosshair guides to help with precise selection
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2
        
        context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [4, 8])
        
        // Horizontal guide
        context.move(to: CGPoint(x: 0, y: centerY))
        context.addLine(to: CGPoint(x: bounds.width, y: centerY))
        context.strokePath()
        
        // Vertical guide  
        context.move(to: CGPoint(x: centerX, y: 0))
        context.addLine(to: CGPoint(x: centerX, y: bounds.height))
        context.strokePath()
    }
    
    // MARK: - Touch Handling
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        print("🔍 DEBUG: SpatialSearchOverlay hitTest - point: \(point), bounds: \(bounds), isSearchMode: \(isSearchMode)")
        
        if isSearchMode && bounds.contains(point) {
            print("🔍 DEBUG: SpatialSearchOverlay hitTest - returning self for search mode")
            return self
        }
        
        print("🔍 DEBUG: SpatialSearchOverlay hitTest - returning nil")
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("🔍 DEBUG: SpatialSearchOverlay touchesBegan - isSearchMode: \(isSearchMode)")
        guard isSearchMode, let touch = touches.first else { 
            print("🔍 DEBUG: SpatialSearchOverlay touchesBegan - conditions not met")
            return 
        }
        
        startPoint = touch.location(in: self)
        currentRect = nil
        searchArea = nil
        setNeedsDisplay()
        print("🔍 DEBUG: SpatialSearchOverlay touchesBegan - startPoint: \(startPoint!)")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isSearchMode, 
              let touch = touches.first,
              let start = startPoint else { 
            print("🔍 DEBUG: SpatialSearchOverlay touchesMoved - conditions not met")
            return 
        }
        
        let currentPoint = touch.location(in: self)
        currentRect = CGRect(
            x: min(start.x, currentPoint.x),
            y: min(start.y, currentPoint.y),
            width: abs(currentPoint.x - start.x),
            height: abs(currentPoint.y - start.y)
        )
        
        print("🔍 DEBUG: SpatialSearchOverlay touchesMoved - currentRect: \(currentRect!)")
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("🔍 DEBUG: SpatialSearchOverlay touchesEnded - currentRect: \(currentRect?.debugDescription ?? "nil")")
        guard isSearchMode, let rect = currentRect else { 
            print("🔍 DEBUG: SpatialSearchOverlay touchesEnded - conditions not met")
            return 
        }
        
        // Convert to normalized coordinates (0-1)
        let normalizedRect = CGRect(
            x: rect.origin.x / bounds.width,
            y: rect.origin.y / bounds.height,
            width: rect.width / bounds.width,
            height: rect.height / bounds.height
        )
        
        print("🔍 DEBUG: SpatialSearchOverlay touchesEnded - normalizedRect: \(normalizedRect)")
        
        // Only accept rectangles with minimum size
        if normalizedRect.width > 0.05 && normalizedRect.height > 0.05 {
            searchArea = normalizedRect
            onAreaSelected?(normalizedRect)
            print("🔍 DEBUG: SpatialSearchOverlay touchesEnded - area selected and callback triggered")
        } else {
            print("🔍 DEBUG: SpatialSearchOverlay touchesEnded - area too small, ignoring")
        }
        
        currentRect = nil
        startPoint = nil
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentRect = nil
        startPoint = nil
        setNeedsDisplay()
    }
    
    // MARK: - Pan Gesture Handler
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        print("🔍 DEBUG: handlePanGesture - state: \(gesture.state.rawValue), isSearchMode: \(isSearchMode)")
        
        guard isSearchMode else {
            print("🔍 DEBUG: handlePanGesture - not in search mode, ignoring")
            return
        }
        
        let location = gesture.location(in: self)
        print("🔍 DEBUG: handlePanGesture - location: \(location)")
        
        switch gesture.state {
        case .began:
            print("🔍 DEBUG: handlePanGesture - BEGAN")
            startPoint = location
            currentRect = nil
            searchArea = nil
            setNeedsDisplay()
            
        case .changed:
            guard let start = startPoint else { return }
            currentRect = CGRect(
                x: min(start.x, location.x),
                y: min(start.y, location.y),
                width: abs(location.x - start.x),
                height: abs(location.y - start.y)
            )
            print("🔍 DEBUG: handlePanGesture - CHANGED, currentRect: \(currentRect!)")
            setNeedsDisplay()
            
        case .ended:
            guard let rect = currentRect else { return }
            print("🔍 DEBUG: handlePanGesture - ENDED")
            
            // Convert to normalized coordinates (0-1)
            let normalizedRect = CGRect(
                x: rect.origin.x / bounds.width,
                y: rect.origin.y / bounds.height,
                width: rect.width / bounds.width,
                height: rect.height / bounds.height
            )
            
            print("🔍 DEBUG: handlePanGesture - normalizedRect: \(normalizedRect)")
            
            // Only accept rectangles with minimum size
            if normalizedRect.width > 0.05 && normalizedRect.height > 0.05 {
                searchArea = normalizedRect
                onAreaSelected?(normalizedRect)
                print("🔍 DEBUG: handlePanGesture - area selected and callback triggered")
            } else {
                print("🔍 DEBUG: handlePanGesture - area too small, ignoring")
            }
            
            currentRect = nil
            startPoint = nil
            setNeedsDisplay()
            
        case .cancelled, .failed:
            print("🔍 DEBUG: handlePanGesture - CANCELLED/FAILED")
            currentRect = nil
            startPoint = nil
            setNeedsDisplay()
            
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SpatialSearchOverlay: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let shouldReceive = isSearchMode
        print("🔍 DEBUG: SpatialSearchOverlay gestureRecognizer shouldReceive - \(shouldReceive), isSearchMode: \(isSearchMode)")
        return shouldReceive
    }
}

// MARK: - DesignSystem Extension

extension DesignSystem.Colors {
    static var accent: Color {
        return Color.orange // Bright accent color for search UI
    }
}

