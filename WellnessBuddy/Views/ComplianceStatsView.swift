//
//  ComplianceStatsView.swift
//  WellnessBuddy
//
//  Created for Health Practitioners & Male Clients.
//

import SwiftUI

/// Compliance & Male Performance Progress Dashboard
public struct ComplianceStatsView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Adherence Highlight Banner
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("REGIMEN ADHERENCE RATE")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .tracking(1.0)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("\(viewModel.adherencePercentage)%")
                                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("Consistent")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.warmClay)
                                }
                            }
                            Spacer()
                            
                            // Flame / Streak Icon
                            ZStack {
                                Circle()
                                    .fill(Color.warmEmber.opacity(0.25))
                                    .frame(width: 54, height: 54)
                                
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.warmEmber)
                            }
                        }
                        
                        ProgressView(value: Double(viewModel.adherencePercentage), total: 100.0)
                            .tint(.warmEmber)
                            .background(Color.white.opacity(0.2))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .clipShape(Capsule())
                        
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.shield.fill")
                                Text("\(viewModel.currentStreakDays)-Day Active Streak")
                            }
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("Target: 95%+")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(20)
                    .background(Color.calmPine)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.calmPine.opacity(0.2), radius: 12, x: 0, y: 6)
                    
                    // Daily Compliance Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("LAST 7 DAYS ADHERENCE LOG")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.calmTextSecondary)
                            .tracking(1.0)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<7) { dayOffset in
                                let days = ["M", "T", "W", "T", "F", "S", "S"]
                                let isCompleted = dayOffset < 6 // demo data
                                
                                VStack(spacing: 8) {
                                    Text(days[dayOffset])
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(.calmTextSecondary)
                                    
                                    ZStack {
                                        Circle()
                                            .fill(isCompleted ? Color.calmSage : Color.calmLightSage)
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: isCompleted ? "checkmark" : "minus")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(isCompleted ? .white : .calmTextSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .calmCardStyle()
                    }
                    
                    // Timing Schedule Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TIMING SCHEDULE BREAKDOWN")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.calmTextSecondary)
                            .tracking(1.0)
                        
                        ForEach(TimingSchedule.allCases) { timing in
                            let count = viewModel.currentProtocol.items.filter { $0.timingSchedule == timing }.count
                            
                            HStack {
                                SchedulePillView(schedule: timing, isSelected: false)
                                
                                Text(timing.description)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.calmTextSecondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(count) Doses")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.calmPine)
                            }
                            .calmCardStyle(padding: 12, cornerRadius: 14)
                        }
                    }
                    
                    // Recent Dose History Log
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT LOG HISTORY")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.calmTextSecondary)
                            .tracking(1.0)
                        
                        ForEach(viewModel.doseLogs) { log in
                            HStack {
                                Image(systemName: log.status == .completed ? "checkmark.circle.fill" : "clock.fill")
                                    .foregroundColor(log.status == .completed ? .calmSage : .warmEmber)
                                    .font(.system(size: 18))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.itemName)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.calmPine)
                                    
                                    Text("\(log.timingSchedule.rawValue) • \(log.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.calmTextSecondary)
                                }
                                Spacer()
                                
                                Text(log.status.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(log.status == .completed ? Color.calmSage.opacity(0.12) : Color.warmEmber.opacity(0.12))
                                    .foregroundColor(log.status == .completed ? .calmSage : .warmEmber)
                                    .clipShape(Capsule())
                            }
                            .calmCardStyle(padding: 12, cornerRadius: 14)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.groundedLinen.ignoresSafeArea())
            .navigationTitle("Compliance Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
