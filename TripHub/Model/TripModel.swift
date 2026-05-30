import Foundation
import SwiftData

// ============================================================
// MARK: - TripModel (SwiftData)
// ============================================================
// Ini adalah model utama untuk sebuah "Trip" (perjalanan).
// Satu Trip bisa punya banyak Destinasi dan banyak Dokumen Umum.

@Model
final class TripModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var endDate: Date

    // Seed untuk menentukan warna/gambar acak kartu trip di UI
    var imageSeed: Int
    var isPinned: Bool

    // Deskripsi opsional untuk trip ini (bisa diisi atau dikosongkan)
    var tripDescription: String?

    // Foto sampul trip dalam format JPEG bytes (opsional)
    // Disimpan langsung di database agar mudah diakses
    var coverImageData: Data?

    // --- Relasi ke Child (Cascade Delete) ---
    // Jika Trip ini dihapus, semua Destinasinya ikut terhapus otomatis
    @Relationship(deleteRule: .cascade, inverse: \DestinationModel.trip)
    var destinations: [DestinationModel] = []

    // Jika Trip ini dihapus, semua Dokumen Umumnya ikut terhapus otomatis
    @Relationship(deleteRule: .cascade, inverse: \DocumentModel.trip)
    var generalDocuments: [DocumentModel] = []

    // --- Inisialisasi ---
    // Catatan: Di SwiftData, kita TIDAK bisa langsung isi relasi di init.
    // Isi `destinations` dan `generalDocuments` SETELAH objek dibuat dan dimasukkan ke context.
    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date,
        endDate: Date,
        imageSeed: Int? = nil,
        isPinned: Bool = false,
        tripDescription: String? = nil,
        coverImageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.imageSeed = imageSeed ?? Int.random(in: 0...2)
        self.isPinned = isPinned
        self.tripDescription = tripDescription
        self.coverImageData = coverImageData
    }

    // --- Helper: Status Perjalanan ---

    // Apakah trip ini sedang berlangsung hari ini?
    func isOngoing(at date: Date, calendar: Calendar = .current) -> Bool {
        return normalizedStart(in: calendar) <= date && normalizedEnd(in: calendar) >= date
    }

    // Apakah trip ini akan datang (belum mulai)?
    func isUpcoming(at date: Date, calendar: Calendar = .current) -> Bool {
        return normalizedStart(in: calendar) > date
    }

    // Apakah trip ini sudah selesai?
    func isPast(at date: Date, calendar: Calendar = .current) -> Bool {
        return normalizedEnd(in: calendar) < date
    }

    // Normalisasi tanggal mulai ke awal hari (00:00:00)
    func normalizedStart(in calendar: Calendar = .current) -> Date {
        return calendar.startOfDay(for: startDate)
    }

    // Normalisasi tanggal selesai ke akhir hari (23:59:59)
    func normalizedEnd(in calendar: Calendar = .current) -> Date {
        let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate
        return nextDay.addingTimeInterval(-1)
    }

    // --- Helper: Ambil semua dokumen di seluruh trip (umum + destinasi) ---
    var allDocuments: [DocumentModel] {
        return generalDocuments + destinations.flatMap { $0.documents }
    }

    // --- Helper: Hitung total dokumen di seluruh trip ---
    var totalDocumentCount: Int {
        return allDocuments.count
    }
}
