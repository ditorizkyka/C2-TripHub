import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@Observable
final class HomeViewModel {
    
    // MARK: - Properties
    
    var sharedFileData: Data? = nil
    var sharedFileIsImage: Bool = true
    var sharedFileOriginalName: String = "Document"
    var isShowingSharedFileSheet: Bool = false
    var deepLinkCategoryNavPath: DocumentCategory? = nil
    
    // MARK: - Methods
    
    func ongoingTrip(from allTrips: [TripModel]) -> TripModel? {
        allTrips.first { $0.isOngoing(at: Date()) }
    }

    func upcomingTrip(from allTrips: [TripModel]) -> TripModel? {
        allTrips
            .filter { $0.isUpcoming(at: Date()) }
            .sorted { $0.normalizedStart() < $1.normalizedStart() }
            .first
    }

    func hasNoActiveTrips(from allTrips: [TripModel]) -> Bool {
        ongoingTrip(from: allTrips) == nil && upcomingTrip(from: allTrips) == nil
    }

    func featuredTrip(from allTrips: [TripModel]) -> TripModel? {
        ongoingTrip(from: allTrips) ?? upcomingTrip(from: allTrips)
    }

    func featuredLabel(from allTrips: [TripModel]) -> String {
        ongoingTrip(from: allTrips) != nil ? "Ongoing Trip" : "Upcoming Trip"
    }

    func tripProgress(for trip: TripModel) -> Double {
        guard trip.isOngoing(at: Date()) else { return 0.0 }
        let totalDays = trip.endDate.timeIntervalSince(trip.startDate)
        let elapsed   = Date().timeIntervalSince(trip.startDate)
        guard totalDays > 0 else { return 1.0 }
        return min(max(elapsed / totalDays, 0), 1)
    }

    func arrivalText(for trip: TripModel) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: trip.endDate)
    }

    func syncWidgetData(featuredTrip: TripModel?) {
        guard let trip = featuredTrip else {
            WidgetDataManager.clear()
            WidgetKit.WidgetCenter.shared.reloadAllTimelines()
            return
        }
        
        let docs = trip.allDocuments
        let ticketCount = docs.filter { $0.categoryRawValue == "Ticket" }.count
        let identityCount = docs.filter { $0.categoryRawValue == "Identity" }.count
        let othersCount = docs.filter { $0.categoryRawValue == "Others" }.count
        
        let recentNames = docs
            .sorted { $0.uploadDate > $1.uploadDate }
            .prefix(9)
            .map { $0.name }
        
        let widgetData = TripWidgetData(
            tripName: trip.name,
            startDate: trip.startDate,
            endDate: trip.endDate,
            ticketCount: ticketCount,
            identityCount: identityCount,
            othersCount: othersCount,
            recentDocumentNames: Array(recentNames)
        )
        
        WidgetDataManager.save(widgetData)
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
    }

    func handleDeepLink(_ destination: DeepLinkDestination?, onClear: @escaping () -> Void, onShareTrigger: () -> Void) {
        guard let destination = destination else { return }

        switch destination {
        case .ticket:   deepLinkCategoryNavPath = .ticket
        case .identity: deepLinkCategoryNavPath = .identity
        case .others:   deepLinkCategoryNavPath = .others
        case .share:    onShareTrigger()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onClear()
        }
    }

    func checkForSharedFile(onClearPending: @escaping () -> Void) {
        guard let meta = SharedFileManager.loadMeta() else { return }

        guard let data = SharedFileManager.loadFileData(fileName: meta.fileName) else {
            SharedFileManager.clearMeta()
            onClearPending()
            return
        }

        sharedFileData = data
        sharedFileIsImage = meta.isImage
        sharedFileOriginalName = meta.originalName

        SharedFileManager.deleteFile(fileName: meta.fileName)
        SharedFileManager.clearMeta()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isShowingSharedFileSheet = true
        }
    }
}
