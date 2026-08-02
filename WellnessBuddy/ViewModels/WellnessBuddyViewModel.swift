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
    
    // Selected Filter for Client Screen
    @Published public var selectedTimingFilter: TimingSchedule? = nil
    
    private var pollTimer: AnyCancellable?
    
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
            
            fetchLiveProtocol()
            fetchDoseLogs()
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
    }
    
    public func fetchDoseLogs() {
        guard !activeClientId.isEmpty else { return }
        APIService.shared.fetchDoseLogs(for: activeClientId) { [weak self] logs in
            guard let self = self else { return }
            self.doseLogs = logs
        }
    }
    
    /// Periodically poll server every 3 seconds while logged in so new practitioner prescriptions pop up automatically!
    public func startLivePolling() {
        pollTimer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isLoggedIn, !self.activeClientId.isEmpty else { return }
                self.fetchLiveProtocol()
            }
    }
    
    /// Fetch live protocol from backend for active logged in client
    public func fetchLiveProtocol() {
        guard !activeClientId.isEmpty else { return }
        
        APIService.shared.fetchProtocol(for: activeClientId) { [weak self] liveProto in
            guard let self = self, let liveProto = liveProto else { return }
            self.currentProtocol = liveProto
            
            if let firstItem = liveProto.items.first {
                // If reminder isn't active or item changed, update reminder
                if self.activeReminder == nil || self.activeReminder?.item.id != firstItem.id {
                    self.activeReminder = ActiveReminderState(
                        item: firstItem,
                        schedule: firstItem.timingSchedule,
                        scheduledTime: Date(),
                        isSnoozed: false
                    )
                }
            } else {
                // Clear active reminder if no items are prescribed!
                self.activeReminder = nil
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
        
        if activeReminder?.item.id == item.id {
            findNextPendingReminder(excluding: item.id)
        }
        
        triggerToast("✓ \(item.name) logged! Adherence updated.")
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
    
    private func findNextPendingReminder(excluding itemId: UUID) {
        let remainingItems = currentProtocol.items.filter { $0.id != itemId }
        if let nextItem = remainingItems.first {
            self.activeReminder = ActiveReminderState(
                item: nextItem,
                schedule: nextItem.timingSchedule,
                scheduledTime: Date().addingTimeInterval(3600),
                isSnoozed: false
            )
        } else {
            self.activeReminder = nil
        }
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
