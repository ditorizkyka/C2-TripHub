import Foundation
import SwiftData

@Observable
final class ExploreTripViewModel {
    
    // MARK: - Properties
    
    var search: String = ""
    var selectedCategory = "All"
    let categories = ["All", "Starred", "Upcoming", "Ongoing", "Past"]
    
    // MARK: - Methods
    
    func filteredTrips(from allTrips: [TripModel]) -> [TripModel] {
        let today = Date()
        let categoryFiltered: [TripModel]
        
        switch selectedCategory {
        case "Starred":
            categoryFiltered = allTrips.filter { $0.isPinned }
        case "Upcoming":
            categoryFiltered = allTrips.filter { $0.isUpcoming(at: today) }
        case "Ongoing":
            categoryFiltered = allTrips.filter { $0.isOngoing(at: today) }
        case "Past":
            categoryFiltered = allTrips.filter { $0.isPast(at: today) }
        default:
            categoryFiltered = allTrips
        }
        
        if search.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { trip in
                trip.name.localizedCaseInsensitiveContains(search)
            }
        }
    }
}
