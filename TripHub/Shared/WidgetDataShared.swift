//
//  WidgetDataShared.swift
//  TripHub
//
//  Shared between the main app and widget extension.
//  ⚠️ IMPORTANT: Add this file to BOTH targets in Xcode:
//     - TripHub (main app)
//     - TripHubWidgetExtension
//

import Foundation

// ============================================================
// MARK: - TripWidgetData
// ============================================================
// Lightweight Codable struct that carries trip info
// from the main app to the widget via App Group UserDefaults.

struct TripWidgetData: Codable {
    let tripName: String
    let startDate: Date
    let endDate: Date
    let ticketCount: Int
    let identityCount: Int
    let othersCount: Int
    
    /// Up to 9 general document names for the 4x4 widget
    let recentDocumentNames: [String]
    
    /// Human-readable date range string (e.g. "5 Days trip from 5 May 2026 to 10 May 2026")
    var dateDescription: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        
        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)
        
        return "\(days) Days trip from \(startStr) to \(endStr)"
    }
    
    /// Total document count across all categories
    var totalDocumentCount: Int {
        ticketCount + identityCount + othersCount
    }
}

// ============================================================
// MARK: - WidgetDataManager
// ============================================================
// Handles reading/writing TripWidgetData to shared UserDefaults.

enum WidgetDataManager {
    
    /// The App Group identifier (must match entitlements)
    static let appGroupID = "group.com.ditorizkyka.TripHub"
    
    /// The key used to store the encoded data
    private static let storageKey = "widgetTripData"
    
    /// Save trip data to shared UserDefaults for the widget to read
    static func save(_ data: TripWidgetData) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
    
    /// Load trip data from shared UserDefaults (called by the widget)
    static func load() -> TripWidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(TripWidgetData.self, from: data)
        else { return nil }
        return decoded
    }
    
    /// Clear stored data (e.g. when all trips are deleted)
    static func clear() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.removeObject(forKey: storageKey)
    }
}
