import Foundation

@Observable
final class TripViewModel {
    
    // MARK: - Properties
    
    var showEditSheet = false
    var showDeleteConfirmation = false
    var selectedDocument: DocumentModel? = nil
    
    // MARK: - Methods

    func tripDurationText(for trip: TripModel) -> String {
        let calendar = Calendar.current
        
        if calendar.isDate(trip.startDate, inSameDayAs: trip.endDate) {
            return "One day trip"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            
            let startString = formatter.string(from: trip.startDate)
            let endString = formatter.string(from: trip.endDate)
            
            return "\(startString) - \(endString)"
        }
    }
}
