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

/// Interactive Done Button with satisfying micro-animation, particle sparkle burst, rotation, and spring scale pulse
public struct PillDoneAnimationButton: View {
    public let title: String
    public let action: () -> Void
    
    @State private var isAnimating: Bool = false
    @State private var showParticles: Bool = false
    @State private var showCheckmarkSeal: Bool = false
    
    public init(title: String = "Done", action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            #if os(iOS)
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
            #endif
            
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                isAnimating = true
                showParticles = true
                showCheckmarkSeal = true
            }
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.easeOut(duration: 0.35)) {
                    isAnimating = false
                    showParticles = false
                    showCheckmarkSeal = false
                }
            }
        }) {
            ZStack {
                // Sparkle Particle Burst Effect
                if showParticles {
                    ForEach(0..<8, id: \.self) { index in
                        let angle = Double(index) * (360.0 / 8.0) * (.pi / 180.0)
                        let distance: CGFloat = 28
                        Circle()
                            .fill(index % 2 == 0 ? Color.paletteSage : Color.paletteOcean)
                            .frame(width: 6, height: 6)
                            .offset(
                                x: showParticles ? cos(angle) * distance : 0,
                                y: showParticles ? sin(angle) * distance : 0
                            )
                            .opacity(showParticles ? 0.9 : 0)
                            .scaleEffect(showParticles ? 1.3 : 0.2)
                    }
                }
                
                HStack(spacing: 6) {
                    Image(systemName: showCheckmarkSeal ? "checkmark.circle.fill" : "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .rotationEffect(.degrees(showCheckmarkSeal ? 360 : 0))
                    
                    Text(showCheckmarkSeal ? "Logged!" : title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(showCheckmarkSeal ? Color.paletteSage : Color.paletteDark)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .scaleEffect(isAnimating ? 1.06 : 1.0)
                .shadow(color: showCheckmarkSeal ? Color.paletteSage.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 3)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

