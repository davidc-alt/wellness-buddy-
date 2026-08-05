//
//  ClientDashboardView.swift
//  WellnessBuddy
//
//  Minimalist Male Client Dashboard matching user color palette & inspiration UI
//

import SwiftUI

public struct ClientDashboardView: View {
    @ObservedObject var viewModel: WellnessBuddyViewModel
    @ObservedObject var notificationService = NotificationService.shared
    @State private var selectedItemForRefill: ProtocolItem?
    
    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 17 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }
    
    public var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Minimalist Inspiration Greeting Header (3 lines)
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(timeGreeting),")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.paletteDark)
                                
                                Text(viewModel.activeClientName.isEmpty ? "Patient" : viewModel.activeClientName)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.paletteOcean)
                                
                                if let profile = viewModel.activeClientProfile, let dob = profile.dob, !dob.isEmpty {
                                    Text("DOB: \(dob)")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.paletteSage)
                                        .padding(.top, 2)
                                }
                            }
                            
                            Spacer()
                            
                            // Switch Mode / Logout Button
                            Button(action: {
                                viewModel.logout()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.paletteDark)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "person.crop.circle.badge.xmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // NOTIFICATION PERMISSION PROMPT CARD (Shows if notifications are not yet authorized!)
                        if !notificationService.isAuthorized {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.paletteOcean.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "bell.badge.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.paletteOcean)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Enable Pill & Prescription Notifications")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.paletteDark)
                                    Text("Tap Allow to get push alerts when your medicine is due")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(.paletteSilver)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    notificationService.requestAuthorization()
                                }) {
                                    Text("Allow")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color.paletteOcean)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                            .calmCardStyle(padding: 14, cornerRadius: 20)
                            .padding(.horizontal, 20)
                        }
                        
                        // PERSISTENT ON-SCREEN REMINDER BANNER (Only if active reminder exists!)
                        if let activeAlert = viewModel.activeReminder {
                            PersistentReminderBannerView(viewModel: viewModel, reminderState: activeAlert)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.spring(), value: viewModel.activeReminder?.id)
                        } else if let summary = viewModel.soonestNextDoseSummary {
                            // NEXT DOSE COUNTDOWN CARD (Shows when doses are up to date!)
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.paletteSage.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "timer")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.paletteSage)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text("✓ Doses Up To Date")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.paletteDark)
                                        Spacer()
                                        Text("Next in \(summary.remainingStr)")
                                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                                            .foregroundColor(.paletteSage)
                                    }
                                    
                                    Text("\(summary.item.name) • \(summary.item.frequencyDescription)")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.paletteSilver)
                                }
                            }
                            .calmCardStyle(padding: 16, cornerRadius: 22)
                            .padding(.horizontal, 20)
                            .transition(.opacity)
                        }
                        
                        // Minimalist Metric Overview Cards
                        HStack(spacing: 14) {
                            // Box 1: Adherence Streak
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Active Streak")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.paletteDark)
                                    Spacer()
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.paletteOcean)
                                }
                                
                                Text("\(viewModel.currentStreakDays) Days")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.paletteDark)
                            }
                            .calmCardStyle(padding: 16, cornerRadius: 22)
                            
                            // Box 2: Daily Doses Done
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Doses Completed")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(.paletteDark)
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.paletteSage)
                                }
                                
                                Text("\(viewModel.todayCompletedCount) of \(viewModel.todayTotalDoses)")
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.paletteDark)
                            }
                            .calmCardStyle(padding: 16, cornerRadius: 22)
                        }
                        .padding(.horizontal, 20)
                        
                        // Practitioner Direct Note Box
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("PRACTITIONER GUIDANCE")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.paletteSilver)
                                    .tracking(1.0)
                                Spacer()
                                Text(viewModel.currentProtocol.practitionerName)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.paletteSage)
                            }
                            
                            Text("“\(viewModel.currentProtocol.practitionerNoteToClient)”")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.paletteDark)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .calmCardStyle(padding: 16, cornerRadius: 20)
                        .padding(.horizontal, 20)
                        
                        // IF PROTOCOL IS EMPTY: SHOW "WAITING FOR YOUR PRACTITIONER" CARD
                        if viewModel.currentProtocol.items.isEmpty {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.paletteOcean.opacity(0.12))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "hourglass")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.paletteOcean)
                                }
                                
                                Text("Waiting for your Practitioner")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.paletteDark)
                                
                                Text("Your practitioner is reviewing your Date of Birth and health intake. Once your custom protocol is prescribed, your daily regimen, timing schedule, and reminders will pop up here live.")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.paletteSilver)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                            .calmCardStyle(padding: 28, cornerRadius: 26)
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                        } else {
                            // Minimalist Schedule Filter Pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChipView(
                                        title: "All",
                                        icon: "square.grid.2x2.fill",
                                        isSelected: viewModel.selectedTimingFilter == nil,
                                        action: { viewModel.selectedTimingFilter = nil }
                                    )
                                    
                                    ForEach(TimingSchedule.allCases) { timing in
                                        FilterChipView(
                                            title: timing.rawValue,
                                            icon: timing.iconName,
                                            isSelected: viewModel.selectedTimingFilter == timing,
                                            action: { viewModel.selectedTimingFilter = timing }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Regimen Items Grouped by Schedule
                            VStack(spacing: 16) {
                                let filteredSchedules = viewModel.selectedTimingFilter != nil ? [viewModel.selectedTimingFilter!] : TimingSchedule.allCases
                                
                                ForEach(filteredSchedules) { schedule in
                                    let itemsForSchedule = viewModel.currentProtocol.items.filter { $0.timingSchedule == schedule }
                                    
                                    if !itemsForSchedule.isEmpty {
                                        VStack(alignment: .leading, spacing: 10) {
                                            // Section Title
                                            HStack(spacing: 6) {
                                                Text(schedule.rawValue)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(.paletteDark)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 20)
                                            
                                            ForEach(itemsForSchedule) { item in
                                                RegimenCardView(item: item, viewModel: viewModel, onRefillTap: {
                                                    FullscriptService.shared.openFullscriptExternal(for: item)
                                                })
                                                .padding(.horizontal, 20)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 4)
                }
                .refreshable {
                    viewModel.fetchLiveProtocol()
                    viewModel.fetchDoseLogs()
                }
                
                // Floating Toast Notification
                if viewModel.showToast, let text = viewModel.toastMessage {
                    ToastBannerView(message: text)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(), value: viewModel.showToast)
                }
                
                // Cute Flame Streak Celebration Modal Overlay
                if viewModel.showStreakCelebration {
                    StreakCelebrationView(
                        streakDays: viewModel.celebrationStreakDays,
                        onDismiss: {
                            withAnimation {
                                viewModel.showStreakCelebration = false
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
            .background(Color.paletteSoftBg.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(item: $selectedItemForRefill) { item in
                FullscriptCheckoutSheet(item: item, viewModel: viewModel)
            }
        }
    }
}

/// Minimalist Filter Chip Button
struct FilterChipView: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(isSelected ? Color.paletteDark : Color.white)
            .foregroundColor(isSelected ? .white : .paletteDark)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(isSelected ? 0.04 : 0.02), radius: 6, x: 0, y: 2)
        }
    }
}

/// Minimalist Regimen Item Card
struct RegimenCardView: View {
    let item: ProtocolItem
    @ObservedObject var viewModel: WellnessBuddyViewModel
    let onRefillTap: () -> Void
    
    @State private var showSnoozeSheet: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                // Category Icon Circle
                ZStack {
                    Circle()
                        .fill(Color.paletteSoftBg)
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: item.category.badgeIcon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.paletteDark)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteDark)
                        
                        Spacer()
                        
                        if viewModel.isDoseDue(for: item) {
                            Text("DUE NOW")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.paletteOcean.opacity(0.12))
                                .foregroundColor(.paletteOcean)
                                .clipShape(Capsule())
                        } else if let nextStr = viewModel.formattedTimeUntilNextDose(for: item) {
                            Text("Next in \(nextStr)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.paletteSage.opacity(0.15))
                                .foregroundColor(.paletteSage)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("\(item.dosageValue.cleanString) \(item.dosageUnit.rawValue) • \(item.brand) • \(item.frequencyDescription)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.paletteSilver)
                }
            }
            
            if !item.practitionerNotes.isEmpty {
                Text(item.practitionerNotes)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.paletteDark.opacity(0.7))
            }
            
            // Action Buttons — Done & Wait buttons only appear when dose is DUE NOW!
            HStack(spacing: 8) {
                if viewModel.isDoseDue(for: item) {
                    PillDoneAnimationButton(action: {
                        viewModel.markDoseDone(for: item, timing: item.timingSchedule)
                    })
                    
                    Button(action: {
                        showSnoozeSheet = true
                    }) {
                        Text("Wait")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.paletteSoftBg)
                            .foregroundColor(.paletteDark)
                            .clipShape(Capsule())
                    }
                    .actionSheet(isPresented: $showSnoozeSheet) {
                        ActionSheet(
                            title: Text("Snooze \(item.name)"),
                            message: Text("Choose when to be reminded:"),
                            buttons: [
                                .default(Text("Wait 15 Minutes")) { viewModel.snoozeDose(for: item, minutes: 15, timing: item.timingSchedule) },
                                .default(Text("Wait 30 Minutes")) { viewModel.snoozeDose(for: item, minutes: 30, timing: item.timingSchedule) },
                                .default(Text("Wait 1 Hour")) { viewModel.snoozeDose(for: item, minutes: 60, timing: item.timingSchedule) },
                                .cancel()
                            ]
                        )
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.paletteSage)
                        Text("Dose Completed")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.paletteDark)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.paletteSage.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Button(action: onRefillTap) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.paletteSoftBg)
                        .foregroundColor(.paletteDark)
                        .clipShape(Circle())
                }
            }
        }
        .calmCardStyle(padding: 18, cornerRadius: 24)
    }
}
