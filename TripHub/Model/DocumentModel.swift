import Foundation
import SwiftUI
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

    // Apakah dokumen ini di-pin/starred oleh user?
    // Default false — wajib ada agar SwiftData tidak crash saat migrasi schema
    @Attribute var isPinned: Bool = false

    // --- Relasi ke Parent ---
    // Dokumen ini milik Trip mana? (untuk generalDocuments)
    var trip: TripModel?

    // Dokumen ini milik Destinasi mana? (untuk dokumen khusus destinasi)
    var destination: DestinationModel?

    // --- Inisialisasi ---
    init(
        id: UUID = UUID(),
        name: String,
        uploadDate: Date = Date(),
        size: Double,
        category: DocumentCategory,
        fileName: String,
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.uploadDate = uploadDate
        self.size = size
        self.categoryRawValue = category.rawValue
        self.fileName = fileName
        self.isPinned = isPinned
    }

    // --- Computed Properties ---

    // Cek apakah file ini adalah gambar berdasarkan ekstensinya
    var isImage: Bool {
        let lowercased = fileName.lowercased()
        if lowercased.hasSuffix(".jpg") { return true }
        if lowercased.hasSuffix(".jpeg") { return true }
        if lowercased.hasSuffix(".png") { return true }
        if lowercased.hasSuffix(".heic") { return true }
        return false
    }

    // ============================================================
    // PENTING: Jangan pakai @Transient computed property dengan setter
    // di SwiftData @Model class. Ini bisa menyebabkan CRASH.
    //
    // Gunakan fungsi biasa (getCategory / setCategory) sebagai gantinya.
    // ============================================================

    // Ambil enum category dari rawValue yang tersimpan
    func getCategory() -> DocumentCategory {
        return DocumentCategory(rawValue: categoryRawValue) ?? .others
    }

    // Set category baru
    func setCategory(_ newCategory: DocumentCategory) {
        categoryRawValue = newCategory.rawValue
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
    
    @ViewBuilder
        var page: some View {
            switch self {
            case .ticket:
                TicketDocuments()
            case .identity:
                IdentityDocuments()
            case .others:
                OtherDocuments()
            }
        }
}
