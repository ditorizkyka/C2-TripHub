//
//  WidgetDataShared.swift
//  TripHubWidget
//
//  ⚠️ This is a COPY of TripHub/Shared/WidgetDataShared.swift
//  In Xcode, you should add the ORIGINAL file to both targets instead
//  of maintaining two copies. Delete this file after adding target membership.
//
//  Alternatively, keep this copy and ensure both files stay in sync.
//

import Foundation

// ============================================================
// MARK: - TripWidgetData
// ============================================================

struct TripWidgetData: Codable {
    let tripName: String
    let startDate: Date
    let endDate: Date
    let ticketCount: Int
    let identityCount: Int
    let othersCount: Int
    
    /// Up to 9 general document names for the 4x4 widget
    let recentDocumentNames: [String]
    
    /// Human-readable date range string
    var dateDescription: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        
        let startStr = formatter.string(from: startDate)
        let endStr = formatter.string(from: endDate)
        
        return "\(days) Days trip from \(startStr) to \(endStr)"
    }
    
    var totalDocumentCount: Int {
        ticketCount + identityCount + othersCount
    }
}

// ============================================================
// MARK: - WidgetDataManager
// ============================================================

enum WidgetDataManager {
    static let appGroupID = "group.com.ditorizkyka.TripHub"
    private static let storageKey = "widgetTripData"
    
    static func save(_ data: TripWidgetData) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: storageKey)
        }
    }
    
    static func load() -> TripWidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(TripWidgetData.self, from: data)
        else { return nil }
        return decoded
    }
    
    static func clear() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.removeObject(forKey: storageKey)
    }
}
