import Foundation

// Ekstensi ini membuat array berisi TripModel memiliki fungsi-fungsi cerdas Anda
extension Array where Element == TripModel {
    
    var ongoingTrip: TripModel? {
        let today = Date()
        return self.first { $0.isOngoing(at: today) }
    }
    
    var pinnedTrip: TripModel? {
        self.first { $0.isPinned }
    }
    
    var featuredTrip: TripModel? {
        let today = Date()
        let ongoing = self.filter { $0.isOngoing(at: today) }
        let upcoming = self.filter { $0.isUpcoming(at: today) }
            .sorted { $0.normalizedStart() < $1.normalizedStart() }
        
        if let pinned = ongoing.first(where: { $0.isPinned }) { return pinned }
        if let pinned = upcoming.first(where: { $0.isPinned }) { return pinned }
        if let first = ongoing.first { return first }
        if let first = upcoming.first { return first }
        return self.first
    }
    
    var allDocuments: [DocumentModel] {
        self.flatMap { trip in
            let generalDocs = trip.generalDocuments
            let destDocs = trip.destinations.flatMap { $0.documents }
            return generalDocs + destDocs
        }
    }
    
    func documents(for categoryRawValue: String) -> [DocumentModel] {
        allDocuments.filter { $0.categoryRawValue == categoryRawValue }
    }
}
