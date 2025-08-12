//
//  DesignSystem.swift
//  ConstruApp
//
//  Created by Eli Barnett on 8/4/25.
//

import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Theme-adaptive semantic colors
        static var primary: Color { 
            ThemeManager.shared.adaptiveColor(.primary) 
        }
        static var secondary: Color { 
            ThemeManager.shared.adaptiveColor(.secondary) 
        }
        static var tertiary: Color { 
            ThemeManager.shared.adaptiveColor(.tertiary) 
        }
        
        // Background colors
        static var background: Color { 
            ThemeManager.shared.adaptiveColor(.background) 
        }
        static var secondaryBackground: Color { 
            ThemeManager.shared.adaptiveColor(.secondaryBackground) 
        }
        static var cardBackground: Color { 
            ThemeManager.shared.adaptiveColor(.cardBackground) 
        }
        static var surfaceBackground: Color { 
            ThemeManager.shared.adaptiveColor(.surfaceBackground) 
        }
        
        // Text colors
        static var primaryText: Color { 
            ThemeManager.shared.adaptiveColor(.primaryText) 
        }
        static var secondaryText: Color { 
            ThemeManager.shared.adaptiveColor(.secondaryText) 
        }
        static var tertiaryText: Color { 
            ThemeManager.shared.adaptiveColor(.tertiaryText) 
        }
        static var placeholderText: Color { 
            ThemeManager.shared.adaptiveColor(.placeholderText) 
        }
        static var buttonText: Color { 
            ThemeManager.shared.adaptiveColor(.buttonText) 
        }
        
        // Interactive colors
        static var interactive: Color { 
            ThemeManager.shared.adaptiveColor(.interactive) 
        }
        static var interactiveLight: Color { 
            ThemeManager.shared.adaptiveColor(.interactiveLight) 
        }
        static var hover: Color { 
            ThemeManager.shared.adaptiveColor(.hover) 
        }
        static var pressed: Color { 
            ThemeManager.shared.adaptiveColor(.pressed) 
        }
        static var disabled: Color { 
            ThemeManager.shared.adaptiveColor(.disabled) 
        }
        
        // Status colors
        static var success: Color { 
            ThemeManager.shared.adaptiveColor(.success) 
        }
        static var warning: Color { 
            ThemeManager.shared.adaptiveColor(.warning) 
        }
        static var error: Color { 
            ThemeManager.shared.adaptiveColor(.error) 
        }
        static var info: Color { 
            ThemeManager.shared.adaptiveColor(.info) 
        }
        
        // Log category colors (theme-adaptive)
        static var electrical: Color { 
            ThemeManager.shared.adaptiveColor(.electrical) 
        }
        static var plumbing: Color { 
            ThemeManager.shared.adaptiveColor(.plumbing) 
        }
        static var structural: Color { 
            ThemeManager.shared.adaptiveColor(.structural) 
        }
        static var hvac: Color { 
            ThemeManager.shared.adaptiveColor(.hvac) 
        }
        static var insulation: Color { 
            ThemeManager.shared.adaptiveColor(.insulation) 
        }
        static var flooring: Color { 
            ThemeManager.shared.adaptiveColor(.flooring) 
        }
        static var roofing: Color { 
            ThemeManager.shared.adaptiveColor(.roofing) 
        }
        static var windows: Color { 
            ThemeManager.shared.adaptiveColor(.windows) 
        }
        static var doors: Color { 
            ThemeManager.shared.adaptiveColor(.doors) 
        }
        static var finishes: Color { 
            ThemeManager.shared.adaptiveColor(.finishes) 
        }
        static var safety: Color { 
            ThemeManager.shared.adaptiveColor(.safety) 
        }
        static var general: Color { 
            ThemeManager.shared.adaptiveColor(.general) 
        }
        
        // Legacy static colors (kept for backwards compatibility)
        @available(*, deprecated, message: "Use adaptive colors instead")
        static let blueprintBlue = Color(red: 0.0, green: 0.3, blue: 0.6)
        @available(*, deprecated, message: "Use adaptive colors instead")
        static let blueprintLightBlue = Color(red: 0.6, green: 0.8, blue: 1.0)
        @available(*, deprecated, message: "Use adaptive colors instead")
        static let architectGray = Color(red: 0.15, green: 0.15, blue: 0.17)
        @available(*, deprecated, message: "Use adaptive colors instead")
        static let lightArchitectGray = Color(red: 0.95, green: 0.95, blue: 0.97)
        @available(*, deprecated, message: "Use adaptive colors instead")
        static let charcoal = Color(red: 0.2, green: 0.2, blue: 0.22)
        @available(*, deprecated, message: "Use adaptive colors instead")
        static let slate = Color(red: 0.35, green: 0.37, blue: 0.4)
        @available(*, deprecated, message: "Use adaptive colors instead")
        static let concrete = Color(red: 0.85, green: 0.85, blue: 0.87)
        @available(*, deprecated, message: "Use adaptive colors instead")
        static let paper = Color(red: 0.98, green: 0.98, blue: 0.99)
        @available(*, deprecated, message: "Use adaptive colors instead")
        static let ink = Color(red: 0.1, green: 0.1, blue: 0.12)
    }
    
    // MARK: - Typography
    struct Typography {
        // Architectural hierarchy - Professional and clean
        static let heroTitle = Font.system(size: 34, weight: .thin, design: .default)
        static let largeTitle = Font.system(size: 28, weight: .light, design: .default)
        static let title1 = Font.system(size: 24, weight: .light, design: .default)
        static let title2 = Font.system(size: 20, weight: .regular, design: .default)
        static let title3 = Font.system(size: 18, weight: .medium, design: .default)
        static let subtitle = Font.system(size: 16, weight: .regular, design: .default)
        
        // Body text hierarchy
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let body = Font.system(size: 15, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 15, weight: .medium, design: .default)
        static let bodySemibold = Font.system(size: 15, weight: .semibold, design: .default)
        static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
        
        // Supporting text
        static let callout = Font.system(size: 14, weight: .medium, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        
        // Architectural context-specific styles
        static let projectTitle = Font.system(size: 26, weight: .thin, design: .default)
        static let blueprintTitle = Font.system(size: 18, weight: .medium, design: .default)
        static let logTitle = Font.system(size: 16, weight: .semibold, design: .default)
        static let timelineHeader = Font.system(size: 16, weight: .medium, design: .default)
        static let categoryLabel = Font.system(size: 12, weight: .semibold, design: .default)
        
        // Technical/Data styles (for coordinates, measurements, etc.)
        static let monospace = Font.system(size: 13, weight: .regular, design: .monospaced)
        static let monospaceMedium = Font.system(size: 13, weight: .medium, design: .monospaced)
        
        // Interactive element styles
        static let buttonTitle = Font.system(size: 16, weight: .semibold, design: .default)
        static let buttonSmall = Font.system(size: 14, weight: .medium, design: .default)
        static let tabTitle = Font.system(size: 10, weight: .medium, design: .default)
        static let navTitle = Font.system(size: 17, weight: .semibold, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // Grid system
        static let gridUnit: CGFloat = 8
        static let cardPadding: CGFloat = 20
        static let screenPadding: CGFloat = 20
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let card: CGFloat = 12
    }
    
    // MARK: - Shadows
    struct Shadows {
        static var card: Shadow { 
            Shadow(
                color: ThemeManager.shared.adaptiveColor(.cardShadow),
                radius: 8,
                x: 0,
                y: 2
            )
        }
        
        static var floating: Shadow { 
            Shadow(
                color: ThemeManager.shared.adaptiveColor(.floatingShadow),
                radius: 16,
                x: 0,
                y: 4
            )
        }
    }
    
    // MARK: - Animation
    struct Animation {
        // Timing curves inspired by architectural precision
        static let immediate = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let deliberate = SwiftUI.Animation.easeInOut(duration: 0.45)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.6)
        
        // Specialized animations
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bounce = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
        static let smooth = SwiftUI.Animation.easeOut(duration: 0.25)
        static let precise = SwiftUI.Animation.linear(duration: 0.2)
        
        // Context-specific animations
        static let cardAppear = SwiftUI.Animation.easeOut(duration: 0.35)
        static let sheetPresent = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let buttonPress = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let pinPulse = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions
extension View {
    // Card styles with enhanced sophistication
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .shadow(
                color: DesignSystem.Shadows.card.color,
                radius: DesignSystem.Shadows.card.radius,
                x: DesignSystem.Shadows.card.x,
                y: DesignSystem.Shadows.card.y
            )
    }
    
    func floatingStyle() -> some View {
        self
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(
                color: DesignSystem.Shadows.floating.color,
                radius: DesignSystem.Shadows.floating.radius,
                x: DesignSystem.Shadows.floating.x,
                y: DesignSystem.Shadows.floating.y
            )
    }
    
    // Interactive styles with architect-appropriate feedback
    func buttonStyle() -> some View {
        self
            .scaleEffect(1.0)
            .animation(DesignSystem.Animation.buttonPress, value: false)
    }
    
    func pressableStyle() -> some View {
        self
            .scaleEffect(1.0)
            .opacity(1.0)
            .animation(DesignSystem.Animation.quick, value: false)
    }
    
    // Enhanced interactive states
    func interactiveCard() -> some View {
        self
            .cardStyle()
            .scaleEffect(1.0)
            .animation(DesignSystem.Animation.spring, value: false)
    }
    
    // Architectural precision styles
    func architecturalCard() -> some View {
        self
            .background(DesignSystem.Colors.surfaceBackground)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(DesignSystem.Colors.concrete, lineWidth: 0.5)
            )
            .cornerRadius(DesignSystem.CornerRadius.card)
            .shadow(
                color: DesignSystem.Colors.ink.opacity(0.04),
                radius: 2,
                x: 0,
                y: 1
            )
    }
    
    // Accessibility and polish
    func accessibleTap(action: @escaping () -> Void) -> some View {
        self
            .onTapGesture(perform: action)
            .accessibilityAddTraits(.isButton)
    }
    
    // Loading states
    func loadingState(_ isLoading: Bool) -> some View {
        self
            .opacity(isLoading ? 0.6 : 1.0)
            .animation(DesignSystem.Animation.standard, value: isLoading)
    }
    
    // Smooth appearance animations
    func smoothAppear(delay: Double = 0) -> some View {
        self
            .opacity(0)
            .scaleEffect(0.95)
            .onAppear {
                withAnimation(DesignSystem.Animation.cardAppear.delay(delay)) {
                    // Animations handled by parent view
                }
            }
    }
    
    // Professional text styles
    func primaryTextStyle() -> some View {
        self
            .foregroundColor(DesignSystem.Colors.primaryText)
    }
    
    func secondaryTextStyle() -> some View {
        self
            .foregroundColor(DesignSystem.Colors.secondaryText)
    }
    
    func tertiaryTextStyle() -> some View {
        self
            .foregroundColor(DesignSystem.Colors.tertiaryText)
    }
}

// MARK: - Extensions
extension Color {
    func uiColor() -> UIColor {
        return UIColor(self)
    }
}