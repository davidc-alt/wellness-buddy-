//
//  NotificationService.swift
//  WellnessBuddy
//
//  Created for Health Practitioners & Male Clients.
//

import Foundation
import UserNotifications
import Combine

/// Manages interactive local notifications for timing-based supplement & peptide reminders
public class NotificationService: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    public static let shared = NotificationService()
    
    @Published public var isAuthorized: Bool = false
    @Published public var lastReceivedAction: String?
    
    public override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
        checkAuthorizationStatus()
    }
    
    public func checkAuthorizationStatus(completion: ((UNAuthorizationStatus) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
                completion?(settings.authorizationStatus)
            }
        }
    }
    
    public func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Notification Authorization Error: \(error.localizedDescription)")
            } else {
                print("🔔 Notification Authorization Result: \(granted ? "GRANTED" : "DENIED")")
            }
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion?(granted)
            }
        }
    }
    
    public func setupNotificationCategories() {
        let doneAction = UNNotificationAction(
            identifier: "ACTION_DONE",
            title: "✓ Done (Log Dose)",
            options: [.foreground]
        )
        
        let wait15Action = UNNotificationAction(
            identifier: "ACTION_WAIT_15",
            title: "⏳ Wait 15 Mins",
            options: []
        )
        
        let wait30Action = UNNotificationAction(
            identifier: "ACTION_WAIT_30",
            title: "⏳ Wait 30 Mins",
            options: []
        )
        
        let wait1hAction = UNNotificationAction(
            identifier: "ACTION_WAIT_60",
            title: "⏳ Wait 1 Hour",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "WELLNESS_REMINDER_CATEGORY",
            actions: [doneAction, wait15Action, wait30Action, wait1hAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    public func scheduleReminder(for item: ProtocolItem, inSeconds seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Time for \(item.name)"
        content.subtitle = "\(item.timingSchedule.rawValue) • \(item.dosageValue.cleanString) \(item.dosageUnit.rawValue)"
        content.body = item.practitionerNotes.isEmpty ? "Stay consistent with your regimen." : item.practitionerNotes
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "WELLNESS_REMINDER_CATEGORY"
        content.userInfo = ["itemId": item.id.uuidString, "itemName": item.name, "timing": item.timingSchedule.rawValue]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "reminder_\(item.id.uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    public func sendDirectNotification(identifier: String = UUID().uuidString, title: String, subtitle: String = "", body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        if !subtitle.isEmpty { content.subtitle = subtitle }
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "WELLNESS_REMINDER_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: "direct_\(identifier)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
    
    public func cancelReminder(for itemId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["reminder_\(itemId.uuidString)"])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Present banner and sound even when app is in foreground
        completionHandler([.banner, .sound, .list, .badge])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionId = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        DispatchQueue.main.async {
            self.lastReceivedAction = "\(actionId)|\(userInfo["itemId"] as? String ?? "")"
        }
        
        completionHandler()
    }
}

extension Double {
    var cleanString: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
