//
//  StreakCelebrationView.swift
//  WellnessBuddy
//
//  Cute Flame Mascot Streak Celebration Modal (Duolingo-Inspired Fire Mascot)
//

import SwiftUI

/// Outer multi-peak flame body shape with dynamic flickers (Duolingo Fire style)
public struct FlameTeardropShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Start near top curved flame tip
        path.move(to: CGPoint(x: w * 0.52, y: h * 0.02))
        
        // Curve down right top flicker peak
        path.addCurve(
            to: CGPoint(x: w * 0.78, y: h * 0.28),
            control1: CGPoint(x: w * 0.68, y: h * 0.08),
            control2: CGPoint(x: w * 0.82, y: h * 0.18)
        )
        
        // Right side wing flame flicker
        path.addCurve(
            to: CGPoint(x: w * 0.94, y: h * 0.56),
            control1: CGPoint(x: w * 0.88, y: h * 0.38),
            control2: CGPoint(x: w * 0.98, y: h * 0.48)
        )
        
        // Bottom right bulbous curve
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.98),
            control1: CGPoint(x: w * 0.90, y: h * 0.80),
            control2: CGPoint(x: w * 0.74, y: h * 0.98)
        )
        
        // Bottom left bulbous curve
        path.addCurve(
            to: CGPoint(x: w * 0.06, y: h * 0.56),
            control1: CGPoint(x: w * 0.26, y: h * 0.98),
            control2: CGPoint(x: w * 0.10, y: h * 0.80)
        )
        
        // Left side wing flame flicker
        path.addCurve(
            to: CGPoint(x: w * 0.22, y: h * 0.28),
            control1: CGPoint(x: w * 0.02, y: h * 0.48),
            control2: CGPoint(x: w * 0.12, y: h * 0.38)
        )
        
        // Swoop back up left flank to top flame tip
        path.addCurve(
            to: CGPoint(x: w * 0.52, y: h * 0.02),
            control1: CGPoint(x: w * 0.18, y: h * 0.18),
            control2: CGPoint(x: w * 0.36, y: h * 0.08)
        )
        
        path.closeSubpath()
        return path
    }
}

/// Inner glowing flame core inset shape
public struct FlameCoreShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.16))
        
        path.addCurve(
            to: CGPoint(x: w * 0.82, y: h * 0.58),
            control1: CGPoint(x: w * 0.72, y: h * 0.26),
            control2: CGPoint(x: w * 0.86, y: h * 0.44)
        )
        
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.92),
            control1: CGPoint(x: w * 0.78, y: h * 0.80),
            control2: CGPoint(x: w * 0.68, y: h * 0.92)
        )
        
        path.addCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.58),
            control1: CGPoint(x: w * 0.32, y: h * 0.92),
            control2: CGPoint(x: w * 0.22, y: h * 0.80)
        )
        
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.16),
            control1: CGPoint(x: w * 0.14, y: h * 0.44),
            control2: CGPoint(x: w * 0.28, y: h * 0.26)
        )
        
        path.closeSubpath()
        return path
    }
}

/// Cute happy mouth smile path
public struct CuteSmileShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: 0, y: h * 0.1))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.1), control: CGPoint(x: w * 0.5, y: h * 1.3))
        path.closeSubpath()
        
        return path
    }
}

/// Animated Cute Flame Mascot Component (Duolingo Fire Inspired)
public struct CuteFlameMascotView: View {
    @State private var swayAngle: Double = -3.5
    @State private var floatOffset: CGFloat = -6.0
    @State private var eyeBlinkScale: CGFloat = 1.0
    @State private var sparkOffset: CGFloat = 0
    @State private var sparkOpacity: Double = 0.9
    @State private var auraPulse: CGFloat = 1.0
    @State private var coreFlicker: CGFloat = 0.96
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Radiant Fire Aura Glow Backdrop
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.40),
                            Color(red: 1.0, green: 0.35, blue: 0.0).opacity(0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    )
                )
                .frame(width: 230, height: 230)
                .scaleEffect(auraPulse)

            // Floating Spark / Ember Fire Particles
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: CGFloat(i % 2 == 0 ? 8 : 6), height: CGFloat(i % 2 == 0 ? 8 : 6))
                    .offset(
                        x: CGFloat(sin(Double(i) * 0.9) * 55.0),
                        y: -30.0 - sparkOffset - CGFloat(i * 16)
                    )
                    .opacity(sparkOpacity)
                    .scaleEffect(1.0 - (sparkOffset / 120.0))
            }

            // Main Duolingo-style Fire Character Stack
            ZStack {
                // 1. Outer Warm Fire Body
                FlameTeardropShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.78, blue: 0.18), // Electric Flame Gold
                                Color(red: 1.0, green: 0.45, blue: 0.05), // Fire Orange
                                Color(red: 0.92, green: 0.18, blue: 0.05)  // Crimson Red Base
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.05).opacity(0.55), radius: 20, x: 0, y: 10)

                // 2. Inner Glowing Core Flame
                FlameCoreShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.98, blue: 0.75), // Bright Golden Yellow Core
                                Color(red: 1.0, green: 0.82, blue: 0.25)  // Warm Yellow Inner Base
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(coreFlicker)
                    .padding(12)

                // 3. Cute Expressive Face Features
                VStack(spacing: 4) {
                    // Eye & Blush Line
                    HStack(spacing: 24) {
                        // Left Eye
                        ZStack {
                            Ellipse()
                                .fill(Color(red: 0.15, green: 0.12, blue: 0.10))
                                .frame(width: 14, height: 20)
                            
                            // Top Eye Catchlight Shine
                            Circle()
                                .fill(Color.white)
                                .frame(width: 5, height: 5)
                                .offset(x: -2, y: -4)
                            
                            // Bottom Eye Catchlight
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 2.5, height: 2.5)
                                .offset(x: 2, y: 3)
                        }
                        .scaleEffect(y: eyeBlinkScale, anchor: .center)

                        // Right Eye
                        ZStack {
                            Ellipse()
                                .fill(Color(red: 0.15, green: 0.12, blue: 0.10))
                                .frame(width: 14, height: 20)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 5, height: 5)
                                .offset(x: -2, y: -4)
                            
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 2.5, height: 2.5)
                                .offset(x: 2, y: 3)
                        }
                        .scaleEffect(y: eyeBlinkScale, anchor: .center)
                    }
                    
                    // Soft Rosy Cheeks & Cute Mouth Stack
                    ZStack {
                        // Rosy Cheek Blushes
                        HStack(spacing: 38) {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.45))
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(Color(red: 1.0, green: 0.35, blue: 0.35).opacity(0.45))
                                .frame(width: 12, height: 12)
                        }
                        
                        // Happy Smile Mouth with Tongue Inset
                        ZStack(alignment: .bottom) {
                            CuteSmileShape()
                                .fill(Color(red: 0.15, green: 0.12, blue: 0.10))
                                .frame(width: 14, height: 10)
                            
                            Circle()
                                .fill(Color(red: 1.0, green: 0.45, blue: 0.55))
                                .frame(width: 7, height: 6)
                                .offset(y: 1)
                        }
                        .offset(y: 3)
                    }
                }
                .offset(y: 14)
            }
            .frame(width: 150, height: 175)
            .rotationEffect(.degrees(swayAngle))
            .offset(y: floatOffset)
        }
        .onAppear {
            // Floating up/down bobbing motion
            withAnimation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                floatOffset = 6.0
            }
            // Flame sway animation
            withAnimation(Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                swayAngle = 3.5
            }
            // Radiant fire aura pulse
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                auraPulse = 1.14
            }
            // Core flame flicker pulse
            withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                coreFlicker = 1.04
            }
            // Spark embers floating upwards
            withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                sparkOffset = 70
                sparkOpacity = 0.05
            }
            // Cute eye blinking timer
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                withAnimation(.easeIn(duration: 0.10)) {
                    eyeBlinkScale = 0.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeOut(duration: 0.10)) {
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
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }

            // Central Translucent Celebration Card
            VStack(spacing: 18) {
                // Top Flame Badge
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 16))
                    Text("\(streakDays)-DAY STREAK!")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.45, blue: 0.05))
                        .tracking(1.0)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Color(red: 1.0, green: 0.45, blue: 0.05).opacity(0.12))
                .clipShape(Capsule())

                // Animated Cute Duolingo Fire Mascot
                CuteFlameMascotView()
                    .frame(height: 190)
                    .padding(.top, 2)

                // Headline & Encouragement Text
                VStack(spacing: 6) {
                    Text("Streak Active!")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.paletteDark)

                    Text("You've completed all your prescribed doses for today! Come back tomorrow to keep the flame burning.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.paletteSilver)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 10)
                }
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(LinearGradient(colors: [Color.white, Color(red: 1.0, green: 0.7, blue: 0.3).opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
            )
            .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.05).opacity(0.25), radius: 25, x: 0, y: 12)
            .padding(.horizontal, 28)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
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
