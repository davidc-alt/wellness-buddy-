//
//  PersistentReminderBannerView.swift
//  WellnessBuddy
//
//  Minimalist persistent reminder banner matching app inspiration layout
//

import SwiftUI

public struct PersistentReminderBannerView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    let reminderState: ActiveReminderState
    
    @State private var showSnoozeSheet: Bool = false
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Row: Schedule Pill & Status Tag
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: reminderState.schedule.iconName)
                        .font(.system(size: 11, weight: .bold))
                    Text(reminderState.schedule.rawValue.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.paletteSage.opacity(0.15))
                .foregroundColor(.paletteSage)
                .clipShape(Capsule())
                
                Spacer()
                
                if reminderState.isSnoozed, let mins = reminderState.snoozeMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Snoozed \(mins)m")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.paletteOcean)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.paletteOcean)
                            .frame(width: 6, height: 6)
                        Text("DUE NOW")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.paletteOcean)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.paletteOcean.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            // Main Item Details
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.paletteSoftBg)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: reminderState.item.category.badgeIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.paletteDark)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminderState.item.name)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.paletteDark)
                    
                    Text("\(reminderState.item.dosageValue.cleanString) \(reminderState.item.dosageUnit.rawValue) • \(reminderState.item.brand)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.paletteSilver)
                    
                    if !reminderState.item.practitionerNotes.isEmpty {
                        Text("“\(reminderState.item.practitionerNotes)”")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.paletteDark.opacity(0.7))
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }
            }
            
            // Minimalist Action Pills ("Done" & "Wait")
            HStack(spacing: 12) {
                // Wait Pill Button
                Button(action: {
                    showSnoozeSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 13, weight: .bold))
                        Text("Wait")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.paletteSoftBg)
                    .foregroundColor(.paletteDark)
                    .clipShape(Capsule())
                }
                .actionSheet(isPresented: $showSnoozeSheet) {
                    ActionSheet(
                        title: Text("Reschedule Reminder for \(reminderState.item.name)"),
                        message: Text("Select how long to wait before next alert:"),
                        buttons: [
                            .default(Text("⏳ Wait 15 minutes")) {
                                viewModel.snoozeDose(for: reminderState.item, minutes: 15, timing: reminderState.schedule)
                            },
                            .default(Text("⏳ Wait 30 minutes")) {
                                viewModel.snoozeDose(for: reminderState.item, minutes: 30, timing: reminderState.schedule)
                            },
                            .default(Text("⏳ Wait 1 Hour")) {
                                viewModel.snoozeDose(for: reminderState.item, minutes: 60, timing: reminderState.schedule)
                            },
                            .default(Text("🥪 Wait After Next Meal")) {
                                viewModel.snoozeDose(for: reminderState.item, minutes: 120, timing: reminderState.schedule)
                            },
                            .cancel()
                        ]
                    )
                }
                
                // Done Pill Button (Primary Accent)
                Button(action: {
                    viewModel.markDoseDone(for: reminderState.item, timing: reminderState.schedule)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                        Text("Done")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.paletteDark)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
        }
        .calmCardStyle(padding: 20, cornerRadius: 26)
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}
