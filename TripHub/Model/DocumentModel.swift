import Foundation
import SwiftData

// ============================================================
// MARK: - DocumentModel (SwiftData)
// ============================================================
// Ini adalah "catatan" yang disimpan di database SwiftData.
// Ia TIDAK menyimpan file itu sendiri, hanya informasi TENTANG file.
// File fisiknya (PDF/Gambar) disimpan terpisah di folder Documents.

@Model
final class DocumentModel {
    @Attribute(.unique) var id: UUID

    // Nama tampilan dokumen (bisa diubah user, misal: "Tiket Pesawat Jakarta")
    var name: String

    // Tanggal dokumen ini diupload ke TripHub
    var uploadDate: Date

    // Ukuran file dalam megabyte
    var size: Double

    // Kita simpan nama kategori sebagai teks biasa (String)
    // Contoh: "Ticket", "Identity", "Others"
    var categoryRawValue: String

    // ⭐️ KUNCI UTAMA: Ini adalah nama file fisik yang tersimpan di folder
    // Contoh: "A1B2C3D4.pdf" atau "E5F6G7H8.jpg"
    // Dengan ini, kita tahu di mana mencari file di dalam folder trip/destinasi
    var fileName: String

    // --- Relasi ke Parent ---
    // Dokumen ini milik Trip mana? (Opsional, karena bisa juga milik Destinasi)
    var trip: TripModel?

    // Dokumen ini milik Destinasi mana? (Opsional)
    var destination: DestinationModel?

    // --- Inisialisasi ---
    init(
        id: UUID = UUID(),
        name: String,
        uploadDate: Date = Date(),
        size: Double,
        category: DocumentCategory,  // Kita terima enum-nya langsung
        fileName: String
    ) {
        self.id = id
        self.name = name
        self.uploadDate = uploadDate
        self.size = size
        self.categoryRawValue = category.rawValue  // Lalu simpan rawValue-nya
        self.fileName = fileName
    }

    // --- Computed Properties ---

    // Cek apakah file ini adalah gambar berdasarkan ekstensinya
    var isImage: Bool {
        let lowercased = fileName.lowercased()
        return lowercased.hasSuffix(".jpg")
            || lowercased.hasSuffix(".jpeg")
            || lowercased.hasSuffix(".png")
            || lowercased.hasSuffix(".heic")
    }

    // Ambil enum category dari rawValue yang tersimpan
    // @Transient artinya properti ini TIDAK ikut disimpan di database
    @Transient
    var category: DocumentCategory {
        get { DocumentCategory(rawValue: categoryRawValue) ?? .others }
        set { categoryRawValue = newValue.rawValue }
    }
}


// ============================================================
// MARK: - DocumentCategory (Enum)
// ============================================================
// Pilihan kategori dokumen yang bisa dipilih user

enum DocumentCategory: String, CaseIterable, Codable {
    case ticket = "Ticket"
    case identity = "Identity"
    case others = "Others"

    // Judul yang ditampilkan di UI
    var title: String {
        return self.rawValue
    }

    // Icon SF Symbols yang mewakili kategori ini
    var icon: String {
        switch self {
        case .ticket:   return "airplane"
        case .identity: return "person.text.rectangle.fill"
        case .others:   return "doc.text.fill"
        }
    }
}
