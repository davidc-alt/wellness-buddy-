//
//  CalmDesignComponents.swift
//  WellnessBuddy
//
//  Minimalist Design System matching exact user color palette & UI inspiration
//

import SwiftUI

/// Exact Color Palette provided by user:
/// #5C8B7D - Sage Muted Green
/// #2F6B87 - Deep Ocean Slate Blue
/// #A7B0B4 - Cool Muted Silver
/// #EDEFF0 - Soft Light Grey Background
/// #354047 - Dark Charcoal Text & Accent
public extension Color {
    static let paletteSage = Color(red: 0.36, green: 0.55, blue: 0.49)      // #5C8B7D
    static let paletteOcean = Color(red: 0.18, green: 0.42, blue: 0.53)     // #2F6B87
    static let paletteSilver = Color(red: 0.65, green: 0.69, blue: 0.71)    // #A7B0B4
    static let paletteSoftBg = Color(red: 0.93, green: 0.94, blue: 0.94)    // #EDEFF0
    static let paletteDark = Color(red: 0.21, green: 0.25, blue: 0.28)      // #354047
    
    // Derived UI shades
    static let calmPine = Color.paletteDark
    static let calmSage = Color.paletteSage
    static let calmLightSage = Color.paletteSoftBg
    static let groundedLinen = Color.paletteSoftBg
    static let calmTextPrimary = Color.paletteDark
    static let calmTextSecondary = Color.paletteSilver
    static let warmEmber = Color.paletteOcean
    static let warmClay = Color.paletteSage
}

/// Ultra-minimalist Card Container (matching inspiration app layout with 24pt corner radius)
public struct MinimalCardModifier: ViewModifier {
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 24
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.paletteDark.opacity(0.03), radius: 12, x: 0, y: 4)
    }
}

public extension View {
    func calmCardStyle(padding: CGFloat = 20, cornerRadius: CGFloat = 24) -> some View {
        self.modifier(MinimalCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

/// Minimalist Schedule Pill Badge
public struct SchedulePillView: View {
    public let schedule: TimingSchedule
    public var isSelected: Bool = false
    
    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: schedule.iconName)
                .font(.system(size: 11, weight: .semibold))
            
            Text(schedule.rawValue)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            isSelected ? Color.paletteDark : Color.paletteSoftBg
        )
        .foregroundColor(isSelected ? .white : Color.paletteDark)
        .clipShape(Capsule())
    }
}

/// Minimalist Primary Pill Button Style
public struct TactileButtonStyle: ButtonStyle {
    var backgroundColor: Color = .paletteDark
    var foregroundColor: Color = .white
    var cornerRadius: CGFloat = 20
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.85 : 1.0))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Minimalist Secondary Pill Button Style
public struct TactileSecondaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = .paletteSoftBg
    var foregroundColor: Color = .paletteDark
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Toast Banner Overlay
public struct ToastBannerView: View {
    public let message: String
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.paletteSage)
                .font(.system(size: 18, weight: .bold))
            
            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.paletteDark)
        .clipShape(Capsule())
        .shadow(color: Color.paletteDark.opacity(0.2), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 20)
    }
}
