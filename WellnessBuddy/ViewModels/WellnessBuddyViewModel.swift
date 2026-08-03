//
//  WellnessBuddyViewModel.swift
//  WellnessBuddy
//
//  Created for Health Practitioners & Male Clients.
//

import Foundation
import SwiftUI
import Combine

public class WellnessBuddyViewModel: ObservableObject {
    // Mode & Login State
    @Published public var isLoggedIn: Bool = false
    @Published public var isPractitionerMode: Bool = false
    @Published public var activeClientName: String = ""
    @Published public var activeClientId: String = ""
    @Published public var activeClientProfile: ClientProfile?
    
    // Active Protocol (Starts empty!)
    @Published public var currentProtocol: PractitionerProtocol
    
    // Reminders & Active Alerts
    @Published public var activeReminder: ActiveReminderState?
    @Published public var doseLogs: [DoseLogEntry] = []
    
    // Toast Notification / Feedback message
    @Published public var toastMessage: String?
    @Published public var showToast: Bool = false
    
    // Flame Mascot Streak Celebration Modal
    @Published public var showStreakCelebration: Bool = false
    @Published public var celebrationStreakDays: Int = 1
    
    // Selected Filter for Client Screen
    @Published public var selectedTimingFilter: TimingSchedule? = nil
    
    private var pollTimer: AnyCancellable?
    
    private var lastKnownItemCount: Int = 0
    private var lastKnownPractitionerNote: String = ""
    private var notifiedDueItemIds: Set<UUID> = []
    
    public init() {
        // Default clean state with NO fake items!
        self.currentProtocol = PractitionerProtocol(
            title: "Male Wellness & Supplement Protocol",
            practitionerName: "Practitioner Luba Vitti",
            practitionerTitle: "Integrative Health Specialist",
            clientName: "Patient",
            clientGoal: "Waiting for practitioner intake...",
            items: [],
            practitionerNoteToClient: "Waiting for your practitioner to prescribe your custom protocol."
        )
        self.activeReminder = nil
        self.doseLogs = []
        
        NotificationService.shared.requestAuthorization()
        restoreSessionIfAvailable()
        startLivePolling()
    }
    
    // MARK: - Session Persistence for Multi-User & Auto-Login
    
    public func saveSession(client: ClientProfile) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "wb_is_logged_in")
        defaults.set(client.id, forKey: "wb_active_client_id")
        defaults.set(client.name, forKey: "wb_active_client_name")
        defaults.set(client.dob ?? "", forKey: "wb_active_client_dob")
        defaults.set(client.email, forKey: "wb_active_client_email")
        defaults.set(client.goal ?? "", forKey: "wb_active_client_goal")
        defaults.set(client.practitionerNote ?? "", forKey: "wb_active_client_practitioner_note")
    }
    
    private func persistProtocolItemsLocally(_ items: [ProtocolItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "wb_saved_protocol_items")
        }
    }

    private func loadLocallyPersistedProtocolItems() -> [ProtocolItem] {
        if let data = UserDefaults.standard.data(forKey: "wb_saved_protocol_items"),
           let items = try? JSONDecoder().decode([ProtocolItem].self, from: data) {
            return items
        }
        return []
    }

    public func restoreSessionIfAvailable() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "wb_is_logged_in"),
           let clientId = defaults.string(forKey: "wb_active_client_id"),
           !clientId.isEmpty {
            let name = defaults.string(forKey: "wb_active_client_name") ?? "Patient"
            let dob = defaults.string(forKey: "wb_active_client_dob")
            let email = defaults.string(forKey: "wb_active_client_email") ?? ""
            let goal = defaults.string(forKey: "wb_active_client_goal")
            let note = defaults.string(forKey: "wb_active_client_practitioner_note")
            
            let restoredProfile = ClientProfile(
                id: clientId,
                name: name,
                dob: dob,
                email: email,
                goal: goal,
                practitionerNote: note
            )
            
            self.activeClientId = clientId
            self.activeClientName = name
            self.activeClientProfile = restoredProfile
            self.isLoggedIn = true
            
            let localItems = loadLocallyPersistedProtocolItems()
            if !localItems.isEmpty {
                self.currentProtocol.items = localItems
            }
            
            // Restore patient profile & pills to server live so server & practitioner studio get re-populated after deploy!
            APIService.shared.restoreSessionOnServer(client: restoredProfile, protocolItems: localItems) { [weak self] returnedClient, items in
                guard let self = self else { return }
                if let returnedClient = returnedClient {
                    self.activeClientId = returnedClient.id
                    self.activeClientName = returnedClient.name
                    self.activeClientProfile = returnedClient
                    self.saveSession(client: returnedClient)
                }
                if !items.isEmpty {
                    self.currentProtocol.items = items
                    self.persistProtocolItemsLocally(items)
                }
                self.fetchLiveProtocol()
                self.fetchDoseLogs()
            }
        }
    }
    
    public func clearSavedSession() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "wb_is_logged_in")
        defaults.removeObject(forKey: "wb_active_client_id")
        defaults.removeObject(forKey: "wb_active_client_name")
        defaults.removeObject(forKey: "wb_active_client_dob")
        defaults.removeObject(forKey: "wb_active_client_email")
        defaults.removeObject(forKey: "wb_active_client_goal")
        defaults.removeObject(forKey: "wb_active_client_practitioner_note")
        defaults.removeObject(forKey: "wb_saved_protocol_items")
    }
    
    public func fetchDoseLogs() {
        guard !activeClientId.isEmpty else { return }
        APIService.shared.fetchDoseLogs(for: activeClientId) { [weak self] logs in
            guard let self = self else { return }
            self.doseLogs = logs
            self.evaluateAndScheduleReminders()
        }
    }
    
    /// Periodically poll server every 5 seconds while logged in so new practitioner prescriptions & dose logs pop up automatically!
    public func startLivePolling() {
        pollTimer = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isLoggedIn, !self.activeClientId.isEmpty else { return }
                self.fetchLiveProtocol()
                self.fetchDoseLogs()
            }
    }
    
    /// Fetch live protocol from backend for active logged in client
    public func fetchLiveProtocol() {
        guard !activeClientId.isEmpty else { return }
        
        APIService.shared.fetchProtocol(for: activeClientId) { [weak self] liveProto in
            guard let self = self, let liveProto = liveProto else { return }
            
            // Only mutate state and trigger SwiftUI view updates if the protocol actually changed!
            if self.currentProtocol != liveProto {
                // Detect practitioner updates to protocol or guidance note
                if self.lastKnownItemCount > 0 {
                    if liveProto.items.count > self.lastKnownItemCount || liveProto.practitionerNoteToClient != self.lastKnownPractitionerNote {
                        NotificationService.shared.sendDirectNotification(
                            title: "🌿 Prescription Updated",
                            subtitle: "Practitioner Luba Vitti",
                            body: "Your practitioner has updated your prescribed supplement protocol and guidance notes."
                        )
                        self.triggerToast("🌿 Prescription updated live by Practitioner Luba Vitti!")
                    }
                }
                
                self.lastKnownItemCount = liveProto.items.count
                self.lastKnownPractitionerNote = liveProto.practitionerNoteToClient
                self.currentProtocol = liveProto
                self.persistProtocolItemsLocally(liveProto.items)
                self.evaluateAndScheduleReminders()
            }
        }
    }
    
    // MARK: - Frequency Interval & Dynamic Reminder Calculations
    
    public func lastCompletedDoseLog(for itemId: UUID) -> DoseLogEntry? {
        return doseLogs.first(where: { $0.itemId == itemId && $0.status == .completed })
    }
    
    public func nextDoseTime(for item: ProtocolItem) -> Date? {
        if let lastLog = lastCompletedDoseLog(for: item.id) {
            return lastLog.timestamp.addingTimeInterval(item.intervalHoursCalculated * 3600)
        }
        return nil // Never logged -> due now
    }
    
    public func isDoseDue(for item: ProtocolItem) -> Bool {
        guard let dueTime = nextDoseTime(for: item) else { return true }
        return Date() >= dueTime
    }
    
    public func timeUntilNextDose(for item: ProtocolItem) -> TimeInterval? {
        guard let dueTime = nextDoseTime(for: item) else { return nil }
        let diff = dueTime.timeIntervalSince(Date())
        return diff > 0 ? diff : nil
    }
    
    public func formattedTimeUntilNextDose(for item: ProtocolItem) -> String? {
        guard let remainingSeconds = timeUntilNextDose(for: item) else { return nil }
        let totalMinutes = Int(ceil(remainingSeconds / 60.0))
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else if mins > 0 {
            return "\(mins)m"
        } else {
            return "less than 1 minute"
        }
    }
    
    public var soonestNextDoseSummary: (item: ProtocolItem, remainingStr: String)? {
        let itemsWithNextDose = currentProtocol.items.compactMap { item -> (ProtocolItem, TimeInterval, String)? in
            guard let remSecs = timeUntilNextDose(for: item), let formatted = formattedTimeUntilNextDose(for: item) else { return nil }
            return (item, remSecs, formatted)
        }
        guard let soonest = itemsWithNextDose.min(by: { $0.1 < $1.1 }) else { return nil }
        return (soonest.0, soonest.2)
    }
    
    public func evaluateAndScheduleReminders() {
        guard isLoggedIn, !activeClientId.isEmpty else { return }
        
        // Find if any prescribed item is currently due
        if let dueItem = currentProtocol.items.first(where: { isDoseDue(for: $0) }) {
            if activeReminder == nil || activeReminder?.item.id != dueItem.id {
                self.activeReminder = ActiveReminderState(
                    item: dueItem,
                    schedule: dueItem.timingSchedule,
                    scheduledTime: Date(),
                    isSnoozed: false
                )
            }
            
            // Send local notification for due pill if not already notified for this cycle
            if !notifiedDueItemIds.contains(dueItem.id) {
                NotificationService.shared.sendDirectNotification(
                    identifier: dueItem.id.uuidString,
                    title: "⏰ Time for \(dueItem.name)",
                    subtitle: "\(dueItem.dosageValue.cleanString) \(dueItem.dosageUnit.rawValue) • \(dueItem.timingSchedule.rawValue)",
                    body: dueItem.practitionerNotes.isEmpty ? "Take as directed by Practitioner Luba Vitti." : dueItem.practitionerNotes
                )
                notifiedDueItemIds.insert(dueItem.id)
            }
        } else {
            // All due doses have been logged! Hide in-app banner until next dose time
            self.activeReminder = nil
        }
        
        // Clear notification tracking for items that are no longer due
        for item in currentProtocol.items {
            if !isDoseDue(for: item) {
                notifiedDueItemIds.remove(item.id)
            }
        }
    }
    
    public func logout() {
        clearSavedSession()
        self.isLoggedIn = false
        self.activeClientProfile = nil
        self.activeClientId = ""
        self.activeClientName = ""
        self.currentProtocol.items = []
        self.activeReminder = nil
        self.doseLogs = []
    }
    
    // MARK: - Reminder Banner Actions ("Done" and "Wait")
    
    public func markDoseDone(for item: ProtocolItem, timing: TimingSchedule) {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        let success = UINotificationFeedbackGenerator()
        success.notificationOccurred(.success)
        #endif
        
        let log = DoseLogEntry(
            itemId: item.id,
            itemName: item.name,
            timestamp: Date(),
            status: .completed,
            timingSchedule: timing,
            note: "Logged on time"
        )
        doseLogs.insert(log, at: 0)
        
        APIService.shared.logDoseEvent(clientId: activeClientId, itemId: item.id, itemName: item.name, timingSchedule: timing, status: .completed)
        
        if let index = currentProtocol.items.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = currentProtocol.items[index]
            if updatedItem.totalServingsRemaining > 0 {
                updatedItem.totalServingsRemaining -= 1
            }
            currentProtocol.items[index] = updatedItem
        }
        
        // Schedule next local notification for exact repeat interval (e.g. 4h, 8h, 12h, 24h)
        let intervalSecs = item.intervalHoursCalculated * 3600
        NotificationService.shared.scheduleReminder(for: item, inSeconds: intervalSecs)
        
        // Re-evaluate active reminder state (banner disappears for this item!)
        evaluateAndScheduleReminders()
        
        let items = currentProtocol.items
        let remainingDue = items.filter { isDoseDue(for: $0) }
        
        // Trigger streak celebration ONLY when ALL pills are completed for the FIRST time today!
        if !items.isEmpty && remainingDue.isEmpty {
            let todayKey = "lastStreakCelebrationDate_\(activeClientId)"
            let todayStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            let lastDateStr = UserDefaults.standard.string(forKey: todayKey)
            
            if lastDateStr != todayStr {
                UserDefaults.standard.set(todayStr, forKey: todayKey)
                self.celebrationStreakDays = max(1, currentStreakDays)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        self.showStreakCelebration = true
                    }
                }
            }
        }
        
        let countdownStr = formattedTimeUntilNextDose(for: item) ?? "in \(Int(item.intervalHoursCalculated))h"
        triggerToast("✓ \(item.name) logged! Next dose in \(countdownStr).")
    }
    
    public func snoozeDose(for item: ProtocolItem, minutes: Int, timing: TimingSchedule) {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
        
        if var currentAlert = activeReminder, currentAlert.item.id == item.id {
            currentAlert.isSnoozed = true
            currentAlert.snoozeMinutes = minutes
            currentAlert.scheduledTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
            self.activeReminder = currentAlert
        } else {
            self.activeReminder = ActiveReminderState(
                item: item,
                schedule: timing,
                scheduledTime: Date().addingTimeInterval(TimeInterval(minutes * 60)),
                isSnoozed: true,
                snoozeMinutes: minutes
            )
        }
        
        NotificationService.shared.scheduleReminder(for: item, inSeconds: TimeInterval(minutes * 60))
        APIService.shared.logDoseEvent(clientId: activeClientId, itemId: item.id, itemName: item.name, timingSchedule: timing, status: .snoozed)
        
        let log = DoseLogEntry(
            itemId: item.id,
            itemName: item.name,
            timestamp: Date(),
            status: .snoozed,
            timingSchedule: timing,
            note: "Snoozed for \(minutes) mins"
        )
        doseLogs.insert(log, at: 0)
        
        triggerToast("⏳ Reminder snoozed for \(minutes) minutes.")
    }
    
    public func triggerManualReminder(for item: ProtocolItem) {
        self.activeReminder = ActiveReminderState(
            item: item,
            schedule: item.timingSchedule,
            scheduledTime: Date(),
            isSnoozed: false
        )
        triggerToast("Persistent reminder active for \(item.name)")
    }
    
    public func dismissActiveReminder() {
        self.activeReminder = nil
    }
    
    // MARK: - Adherence Metrics & Dynamic Streak Counter
    public var currentStreakDays: Int {
        let calendar = Calendar.current
        let completedLogs = doseLogs.filter { $0.status == .completed }
        guard !completedLogs.isEmpty else { return 0 }
        
        let completedDaysSet = Set(completedLogs.map { calendar.startOfDay(for: $0.timestamp) })
        let sortedDays = completedDaysSet.sorted(by: >)
        
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        guard let mostRecentDay = sortedDays.first,
              mostRecentDay == today || mostRecentDay == yesterday else {
            return 0
        }
        
        var streak = 0
        var checkDay = mostRecentDay
        
        while completedDaysSet.contains(checkDay) {
            streak += 1
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = prevDay
        }
        
        return streak
    }
    
    public var adherencePercentage: Int {
        guard !doseLogs.isEmpty else { return 100 }
        let completed = doseLogs.filter { $0.status == .completed }.count
        let rate = Double(completed) / Double(doseLogs.count) * 100.0
        return Int(min(100, max(0, rate)))
    }
    
    public var todayCompletedCount: Int {
        let calendar = Calendar.current
        return doseLogs.filter { calendar.isDateInToday($0.timestamp) && $0.status == .completed }.count
    }
    
    public var todayTotalDoses: Int {
        return currentProtocol.items.count
    }
    
    // MARK: - Practitioner Protocol Editing
    public func addProtocolItem(_ item: ProtocolItem) {
        currentProtocol.items.append(item)
        if !activeClientId.isEmpty {
            APIService.shared.assignProtocolItem(clientId: activeClientId, item: item)
        }
        triggerToast("Added \(item.name) to client protocol.")
    }
    
    public func updateProtocolItem(_ item: ProtocolItem) {
        if let index = currentProtocol.items.firstIndex(where: { $0.id == item.id }) {
            currentProtocol.items[index] = item
            if !activeClientId.isEmpty {
                APIService.shared.assignProtocolItem(clientId: activeClientId, item: item)
            }
            triggerToast("Updated \(item.name).")
        }
    }
    
    public func removeProtocolItem(at offsets: IndexSet) {
        for index in offsets {
            if index < currentProtocol.items.count {
                let item = currentProtocol.items[index]
                if !activeClientId.isEmpty {
                    APIService.shared.deleteProtocolItem(clientId: activeClientId, itemId: item.id)
                }
            }
        }
        currentProtocol.items.remove(atOffsets: offsets)
    }
    
    public func triggerToast(_ text: String) {
        self.toastMessage = text
        self.showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.showToast = false
        }
    }
}
