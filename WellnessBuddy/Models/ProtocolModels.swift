//
//  ProtocolModels.swift
//  WellnessBuddy
//
//  Created for Health Practitioners & Male Clients.
//

import Foundation
import SwiftUI

/// Timing schedule options tailored for supplement & bio-availability protocols
public enum TimingSchedule: String, Codable, CaseIterable, Identifiable {
    case emptyStomach = "Empty Stomach"
    case withBreakfast = "With Breakfast"
    case withMeal = "With Meal"
    case withLunch = "With Lunch"
    case withDinner = "With Dinner"
    case midDay = "Mid-Day"
    case preWorkout = "Pre-Workout"
    case postWorkout = "Post-Workout"
    case beforeBed = "Before Bed"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .emptyStomach: return "sun.max.fill"
        case .withBreakfast: return "cup.and.saucer.fill"
        case .withMeal: return "fork.knife"
        case .withLunch: return "takeoutbag.and.cup.and.straw.fill"
        case .withDinner: return "wineglass.fill"
        case .midDay: return "sun.haze.fill"
        case .preWorkout: return "figure.run"
        case .postWorkout: return "bolt.fill"
        case .beforeBed: return "moon.stars.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .emptyStomach: return "Take 30+ mins before food or upon waking"
        case .withBreakfast: return "Take with your morning breakfast"
        case .withMeal: return "Take during a meal with healthy fats"
        case .withLunch: return "Take with your mid-day meal"
        case .withDinner: return "Take with evening dinner"
        case .midDay: return "Take mid-afternoon between meals"
        case .preWorkout: return "Take 30-45 mins prior to exercise"
        case .postWorkout: return "Take immediately post exercise for recovery"
        case .beforeBed: return "Take 30-45 mins before sleep"
        }
    }
    
    public var themeColor: Color {
        switch self {
        case .emptyStomach: return .paletteSage
        case .withBreakfast, .withMeal, .withLunch, .withDinner: return .paletteOcean
        case .midDay, .preWorkout, .postWorkout: return .paletteDark
        case .beforeBed: return .paletteSilver
        }
    }
}

/// Category of regimen item
public enum RegimenCategory: String, Codable, CaseIterable, Identifiable {
    case supplement = "Supplement"
    case specializedStack = "Specialized Regimen"
    case vitamin = "Vitamin & Mineral"
    case mineral = "Mineral Support"
    case hormoneSupport = "Hormone Optimization"
    
    public var id: String { rawValue }
    
    public var badgeIcon: String {
        switch self {
        case .supplement: return "pill.fill"
        case .specializedStack: return "sparkles"
        case .vitamin: return "leaf.fill"
        case .mineral: return "square.grid.2x2.fill"
        case .hormoneSupport: return "flame.fill"
        }
    }
}

/// Unit of measurement for protocol items
public enum DosageUnit: String, Codable, CaseIterable {
    case mg = "mg"
    case mcg = "mcg"
    case IU = "IU"
    case ml = "mL"
    case capsules = "caps"
    case scoops = "scoops"
    case sprays = "sprays"
}

/// Represents an individual item in a practitioner's protocol
public struct ProtocolItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var brand: String
    public var category: RegimenCategory
    public var dosageValue: Double
    public var dosageUnit: DosageUnit
    public var timingSchedule: TimingSchedule
    public var frequencyDescription: String // e.g. "Once Daily", "Every 8 Hours"
    public var intervalHours: Double?
    public var practitionerNotes: String
    public var fullscriptProductId: String?
    public var fullscriptRefillUrl: String?
    public var totalServingsRemaining: Int
    public var maxServings: Int
    
    public var intervalHoursCalculated: Double {
        if let hours = intervalHours, hours > 0 {
            return hours
        }
        let lower = frequencyDescription.lowercased()
        if lower.contains("4 hour") || lower.contains("4h") || lower.contains("every 4") { return 4.0 }
        if lower.contains("6 hour") || lower.contains("6h") || lower.contains("every 6") { return 6.0 }
        if lower.contains("8 hour") || lower.contains("8h") || lower.contains("every 8") { return 8.0 }
        if lower.contains("12 hour") || lower.contains("12h") || lower.contains("every 12") { return 12.0 }
        if lower.contains("48 hour") || lower.contains("48h") || lower.contains("every 48") || lower.contains("every 2 day") { return 48.0 }
        return 24.0
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: RegimenCategory,
        dosageValue: Double,
        dosageUnit: DosageUnit,
        timingSchedule: TimingSchedule,
        frequencyDescription: String,
        intervalHours: Double? = nil,
        practitionerNotes: String,
        fullscriptProductId: String? = nil,
        fullscriptRefillUrl: String? = nil,
        totalServingsRemaining: Int = 30,
        maxServings: Int = 30
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.dosageValue = dosageValue
        self.dosageUnit = dosageUnit
        self.timingSchedule = timingSchedule
        self.frequencyDescription = frequencyDescription
        self.intervalHours = intervalHours
        self.practitionerNotes = practitionerNotes
        self.fullscriptProductId = fullscriptProductId
        self.fullscriptRefillUrl = fullscriptRefillUrl
        self.totalServingsRemaining = totalServingsRemaining
        self.maxServings = maxServings
    }
    
    // Custom Decodable initializer for flexibility with backend API types
    enum CodingKeys: String, CodingKey {
        case id, name, brand, category, dosageValue, dosageUnit, timingSchedule, frequencyDescription, intervalHours, practitionerNotes, fullscriptProductId, fullscriptRefillUrl, totalServingsRemaining, maxServings
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = idString.toStableUUID
        } else {
            self.id = UUID()
        }
        
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Supplement"
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand) ?? "Standard"
        
        if let catStr = try? container.decode(String.self, forKey: .category), let cat = RegimenCategory(rawValue: catStr) {
            self.category = cat
        } else {
            self.category = .supplement
        }
        
        self.dosageValue = try container.decodeIfPresent(Double.self, forKey: .dosageValue) ?? 1.0
        
        if let unitStr = try? container.decode(String.self, forKey: .dosageUnit), let unit = DosageUnit(rawValue: unitStr) {
            self.dosageUnit = unit
        } else {
            self.dosageUnit = .mg
        }
        
        if let timingStr = try? container.decode(String.self, forKey: .timingSchedule), let timing = TimingSchedule(rawValue: timingStr) {
            self.timingSchedule = timing
        } else {
            self.timingSchedule = .emptyStomach
        }
        
        self.frequencyDescription = try container.decodeIfPresent(String.self, forKey: .frequencyDescription) ?? "Daily"
        self.intervalHours = try container.decodeIfPresent(Double.self, forKey: .intervalHours)
        self.practitionerNotes = try container.decodeIfPresent(String.self, forKey: .practitionerNotes) ?? ""
        self.fullscriptProductId = try container.decodeIfPresent(String.self, forKey: .fullscriptProductId)
        self.fullscriptRefillUrl = try container.decodeIfPresent(String.self, forKey: .fullscriptRefillUrl)
        self.totalServingsRemaining = try container.decodeIfPresent(Int.self, forKey: .totalServingsRemaining) ?? 30
        self.maxServings = try container.decodeIfPresent(Int.self, forKey: .maxServings) ?? 30
    }
    
    public var isLowStock: Bool {
        return totalServingsRemaining <= 7
    }
}

/// Represents a dose log entry recorded by the client
public struct DoseLogEntry: Identifiable, Codable, Equatable {
    public var id: UUID
    public var itemId: UUID
    public var itemName: String
    public var timestamp: Date
    public var status: DoseStatus
    public var timingSchedule: TimingSchedule
    public var note: String?
    
    public init(id: UUID = UUID(), itemId: UUID, itemName: String, timestamp: Date = Date(), status: DoseStatus, timingSchedule: TimingSchedule, note: String? = nil) {
        self.id = id
        self.itemId = itemId
        self.itemName = itemName
        self.timestamp = timestamp
        self.status = status
        self.timingSchedule = timingSchedule
        self.note = note
    }
}

public enum DoseStatus: String, Codable {
    case completed = "Done"
    case snoozed = "Wait"
    case missed = "Missed"
    case skipped = "Skipped"
    
    public init(fromRaw raw: String) {
        let s = raw.trimmingCharacters(in: .whitespaces)
        if s == "Done" || s == "Completed" || s == "completed" {
            self = .completed
        } else if s == "Wait" || s == "Snoozed" || s == "snoozed" {
            self = .snoozed
        } else if s == "Missed" || s == "missed" {
            self = .missed
        } else if s == "Skipped" || s == "skipped" {
            self = .skipped
        } else {
            self = .completed
        }
    }
}

/// Full protocol prescribed by a practitioner to a client
public struct PractitionerProtocol: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var practitionerName: String
    public var practitionerTitle: String
    public var clientName: String
    public var clientGoal: String
    public var createdDate: Date
    public var items: [ProtocolItem]
    public var practitionerNoteToClient: String
    public var pdfUrl: String?
    public var pdfName: String?
    
    public init(
        id: UUID = UUID(),
        title: String,
        practitionerName: String,
        practitionerTitle: String,
        clientName: String,
        clientGoal: String,
        createdDate: Date = Date(),
        items: [ProtocolItem],
        practitionerNoteToClient: String,
        pdfUrl: String? = nil,
        pdfName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.practitionerName = practitionerName
        self.practitionerTitle = practitionerTitle
        self.clientName = clientName
        self.clientGoal = clientGoal
        self.createdDate = createdDate
        self.items = items
        self.practitionerNoteToClient = practitionerNoteToClient
        self.pdfUrl = pdfUrl
        self.pdfName = pdfName
    }
}

/// Active Reminder State for Persistent On-Screen Alert
public struct ActiveReminderState: Codable, Identifiable, Equatable {
    public var id: UUID
    public var item: ProtocolItem
    public var schedule: TimingSchedule
    public var scheduledTime: Date
    public var isSnoozed: Bool
    public var snoozeMinutes: Int?
    public var isDismissed: Bool
    
    public init(id: UUID = UUID(), item: ProtocolItem, schedule: TimingSchedule, scheduledTime: Date = Date(), isSnoozed: Bool = false, snoozeMinutes: Int? = nil, isDismissed: Bool = false) {
        self.id = id
        self.item = item
        self.schedule = schedule
        self.scheduledTime = scheduledTime
        self.isSnoozed = isSnoozed
        self.snoozeMinutes = snoozeMinutes
        self.isDismissed = isDismissed
    }
}

extension String {
    public var toStableUUID: UUID {
        if let uuid = UUID(uuidString: self) {
            return uuid
        }
        var hash: UInt64 = 5381
        for byte in self.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        let hex1 = String(format: "%08x", UInt32(hash & 0xFFFFFFFF))
        let hex2 = String(format: "%04x", UInt16((hash >> 32) & 0xFFFF))
        let hex3 = String(format: "%04x", UInt16((hash >> 16) & 0xFFFF))
        let hex4 = String(format: "%04x", UInt16(hash & 0xFFFF))
        let hex5 = String(format: "%012x", hash)
        
        let uuidStr = "\(hex1)-\(hex2)-4\(hex3.suffix(3))-\(hex4.suffix(4))-\(hex5.suffix(12))"
        return UUID(uuidString: uuidStr) ?? UUID()
    }
}
