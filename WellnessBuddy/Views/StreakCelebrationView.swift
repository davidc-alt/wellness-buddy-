//
//  StreakCelebrationView.swift
//  WellnessBuddy
//
//  Cute Flame Mascot Streak Celebration Modal
//

import SwiftUI

/// Custom teardrop flame mascot shape matching the cute flame character
public struct FlameTeardropShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Start near the top curved tip
        path.move(to: CGPoint(x: w * 0.58, y: h * 0.05))
        
        // Curve to top right peak
        path.addCurve(
            to: CGPoint(x: w * 0.88, y: h * 0.42),
            control1: CGPoint(x: w * 0.75, y: h * 0.12),
            control2: CGPoint(x: w * 0.92, y: h * 0.28)
        )
        
        // Curve down around bottom right bulb
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.96),
            control1: CGPoint(x: w * 0.85, y: h * 0.72),
            control2: CGPoint(x: w * 0.72, y: h * 0.96)
        )
        
        // Curve around bottom left bulb
        path.addCurve(
            to: CGPoint(x: w * 0.12, y: h * 0.52),
            control1: CGPoint(x: w * 0.28, y: h * 0.96),
            control2: CGPoint(x: w * 0.10, y: h * 0.78)
        )
        
        // Swoop up left flank back to top peak
        path.addCurve(
            to: CGPoint(x: w * 0.58, y: h * 0.05),
            control1: CGPoint(x: w * 0.14, y: h * 0.28),
            control2: CGPoint(x: w * 0.38, y: h * 0.10)
        )
        
        path.closeSubpath()
        return path
    }
}

/// Inner face inset shape
public struct FlameFaceShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.55, y: h * 0.20))
        
        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.50),
            control1: CGPoint(x: w * 0.68, y: h * 0.26),
            control2: CGPoint(x: w * 0.80, y: h * 0.38)
        )
        
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.88),
            control1: CGPoint(x: w * 0.76, y: h * 0.72),
            control2: CGPoint(x: w * 0.68, y: h * 0.88)
        )
        
        path.addCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.55),
            control1: CGPoint(x: w * 0.32, y: h * 0.88),
            control2: CGPoint(x: w * 0.20, y: h * 0.72)
        )
        
        path.addCurve(
            to: CGPoint(x: w * 0.55, y: h * 0.20),
            control1: CGPoint(x: w * 0.24, y: h * 0.38),
            control2: CGPoint(x: w * 0.42, y: h * 0.24)
        )
        
        path.closeSubpath()
        return path
    }
}

/// Animated Cute Flame Mascot Component
public struct CuteFlameMascotView: View {
    @State private var swayAngle: Double = -3.0
    @State private var eyeBlinkScale: CGFloat = 1.0
    @State private var sparkOffset: CGFloat = 0
    @State private var sparkOpacity: Double = 0.8
    @State private var pulseScale: CGFloat = 1.0
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Glowing Backdrop Aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.paletteOcean.opacity(0.35), Color.paletteSage.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(pulseScale)

            // Floating Spark / Ember Particles
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(i % 2 == 0 ? Color.paletteOcean : Color.paletteSage)
                    .frame(width: CGFloat.random(in: 6...10), height: CGFloat.random(in: 6...10))
                    .offset(
                        x: CGFloat(sin(Double(i) * 1.2) * 50.0),
                        y: -40.0 - sparkOffset - CGFloat(i * 18)
                    )
                    .opacity(sparkOpacity)
            }

            // Main Flame Teardrop Body
            ZStack {
                // Outer Flame Body
                FlameTeardropShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.56, blue: 0.98), // Bright Flame Blue
                                Color(red: 0.12, green: 0.38, blue: 0.82)  // Deep Ocean Blue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.18, green: 0.56, blue: 0.98).opacity(0.4), radius: 16, x: 0, y: 8)

                // Soft White Inner Face Inset
                FlameFaceShape()
                    .fill(Color.white)
                    .padding(14)

                // Cute Oval Eyes
                HStack(spacing: 22) {
                    Ellipse()
                        .fill(Color(red: 0.22, green: 0.18, blue: 0.14)) // Dark warm brown/charcoal
                        .frame(width: 10, height: 16)
                        .scaleEffect(y: eyeBlinkScale, anchor: .center)

                    Ellipse()
                        .fill(Color(red: 0.22, green: 0.18, blue: 0.14))
                        .frame(width: 10, height: 16)
                        .scaleEffect(y: eyeBlinkScale, anchor: .center)
                }
                .offset(x: -2, y: 6)
            }
            .frame(width: 140, height: 160)
            .rotationEffect(.degrees(swayAngle))
        }
        .onAppear {
            // Sway animation
            withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                swayAngle = 3.0
            }
            // Backdrop aura pulse
            withAnimation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseScale = 1.12
            }
            // Spark particles floating up
            withAnimation(Animation.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                sparkOffset = 60
                sparkOpacity = 0.1
            }
            // Cute eye blinking timer
            Timer.scheduledTimer(withTimeInterval: 2.8, repeats: true) { _ in
                withAnimation(.easeIn(duration: 0.12)) {
                    eyeBlinkScale = 0.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                    withAnimation(.easeOut(duration: 0.12)) {
                        eyeBlinkScale = 1.0
                    }
                }
            }
        }
    }
}

/// Full Streak Celebration Overlay Modal
public struct StreakCelebrationView: View {
    public var streakDays: Int
    public var onDismiss: () -> Void
    
    @State private var cardScale: CGFloat = 0.5
    @State private var cardOpacity: Double = 0
    
    public init(streakDays: Int, onDismiss: @escaping () -> Void) {
        self.streakDays = streakDays
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Blurred Translucent Overlay Background
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }

            // Central Translucent Celebration Card
            VStack(spacing: 20) {
                // Top Flame Badge
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 16))
                    Text("\(streakDays)-DAY STREAK!")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(.paletteOcean)
                        .tracking(0.8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.paletteOcean.opacity(0.12))
                .clipShape(Capsule())

                // Cute Animated Flame Mascot
                CuteFlameMascotView()
                    .frame(height: 180)
                    .padding(.top, 4)

                // Headline & Encouragement Text
                VStack(spacing: 8) {
                    Text("Streak Started!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.paletteDark)

                    Text("You've completed all your prescribed doses for today! Come back tomorrow to keep the flame alive.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.paletteSilver)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 12)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 28)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .onAppear {
            #if os(iOS)
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
            #endif
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
            
            // Auto-dismiss automatically after 2.5 seconds (No user action required!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismissModal()
            }
        }
    }
    
    private func dismissModal() {
        withAnimation(.easeOut(duration: 0.3)) {
            cardScale = 0.85
            cardOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}
