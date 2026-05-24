import Foundation
import SwiftData

@Model
final class DestinationModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var startTime: Date
    var endDate: Date // Waktu mulai
    var endTime: Date
    
    // 1. Relasi ke Parent (TripModel)
    // Otomatis terhubung karena di TripModel kita sudah set inverse-nya ke properti ini
    var trip: TripModel?
    
    // 2. Relasi ke Child (DocumentModel)
    // Cascade: Jika destinasi ini (misal: "Paris") dihapus, maka tiket Menara Eiffel
    // di dalam array documents ini juga akan ikut terhapus dari database.
    @Relationship(deleteRule: .cascade, inverse: \DocumentModel.destination)
    var documents: [DocumentModel] = []
    
    init(id: UUID = UUID(), name: String, startDate: Date,startTime : Date, endDate: Date, endTime: Date ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.startTime = startTime
        self.endDate = endDate
        self.endTime = endTime
    }
}
