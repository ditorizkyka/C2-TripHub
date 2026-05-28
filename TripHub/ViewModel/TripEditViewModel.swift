import SwiftUI
import SwiftData
import PhotosUI

// ============================================================
// MARK: - TripEditViewModel
// ============================================================
// ViewModel sederhana untuk halaman edit trip.
//
// Cara kerja:
// 1. Saat EditTripView dibuka, kita COPY semua data trip ke sini
// 2. User mengubah data di sini (bukan di TripModel langsung)
// 3. Saat user klik "Save", baru kita tulis balik ke TripModel
//
// Kenapa begini? Supaya kita bisa mendeteksi perubahan (hasChanges)
// dan memberikan dialog konfirmasi jika user mau keluar tanpa simpan.

@Observable
class TripEditViewModel {

    // ─── Copy data dari TripModel ─────────────────────────────────────────────
    // Ini yang user edit. Belum tersimpan ke database sampai saveChanges() dipanggil.
    var name: String
    var tripDescription: String
    var coverImageData: Data?

    // ─── State untuk Photos Picker ────────────────────────────────────────────
    // Binding ke PhotosPicker. Saat berubah, kita load datanya.
    var coverImagePickerItem: PhotosPickerItem? = nil

    // ─── State untuk edit dokumen ─────────────────────────────────────────────
    // Kita buat salinan lokal per dokumen supaya bisa di-track perubahannya
    var editedDocuments: [EditedDocument] = []

    // ─── State untuk dialog & UI ──────────────────────────────────────────────
    var showSaveConfirmation = false    // Dialog: "Simpan perubahan?"
    var showDiscardConfirmation = false // Dialog: "Buang perubahan?"

    // ─── Nilai awal (untuk mendeteksi hasChanges) ─────────────────────────────
    private let originalName: String
    private let originalDescription: String
    private let originalCoverImageData: Data?

    // =========================================================================
    // MARK: - Init
    // =========================================================================

    // Dipanggil saat EditTripView pertama kali muncul.
    // Kita copy semua data trip yang ada ke sini.
    init(trip: TripModel) {
        self.name              = trip.name
        self.tripDescription   = trip.tripDescription ?? ""
        self.coverImageData    = trip.coverImageData

        // Simpan nilai awal supaya kita tahu apakah ada perubahan
        self.originalName             = trip.name
        self.originalDescription      = trip.tripDescription ?? ""
        self.originalCoverImageData   = trip.coverImageData

        // Salin semua dokumen umum trip ke dalam array editedDocuments
        self.editedDocuments = trip.generalDocuments.map {
            EditedDocument(source: $0)
        }
    }

    // =========================================================================
    // MARK: - Computed Properties
    // =========================================================================

    // Apakah ada perubahan dari data aslinya?
    // Dipakai untuk menampilkan dialog discard jika user mau keluar
    var hasChanges: Bool {
        let nameChanged        = name.trimmingCharacters(in: .whitespaces) != originalName
        let descChanged        = tripDescription.trimmingCharacters(in: .whitespaces) != originalDescription
        let imageChanged       = coverImageData != originalCoverImageData
        let docsChanged        = editedDocuments.contains { $0.hasChanges }
        let docsDeleted        = editedDocuments.contains { $0.isMarkedForDeletion }

        return nameChanged || descChanged || imageChanged || docsChanged || docsDeleted
    }

    // Apakah data valid untuk disimpan?
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // =========================================================================
    // MARK: - Load Photo
    // =========================================================================

    // Dipanggil dari .onChange(of: coverImagePickerItem) di View
    // Mengubah PhotosPickerItem menjadi raw Data yang bisa disimpan ke SwiftData
    func loadSelectedPhoto() async {
        guard let item = coverImagePickerItem else {
            coverImageData = nil
            return
        }

        if let data = try? await item.loadTransferable(type: Data.self) {
            coverImageData = data
        }
    }

    // =========================================================================
    // MARK: - Save Changes
    // =========================================================================

    // Tulis semua perubahan kembali ke TripModel (di SwiftData).
    // Dipanggil SETELAH user konfirmasi di dialog.
    func saveChanges(to trip: TripModel, context: ModelContext) {
        // Simpan nama
        trip.name = name.trimmingCharacters(in: .whitespaces)

        // Simpan deskripsi (nil jika kosong)
        let desc = tripDescription.trimmingCharacters(in: .whitespaces)
        trip.tripDescription = desc.isEmpty ? nil : desc

        // Simpan foto sampul
        trip.coverImageData = coverImageData

        // Simpan perubahan dokumen
        for editedDoc in editedDocuments {
            if editedDoc.isMarkedForDeletion {
                // Hapus dokumen dari database
                if let source = editedDoc.source {
                    context.delete(source)
                }
            } else {
                // Update nama dan kategori dokumen
                editedDoc.source?.name = editedDoc.name
                editedDoc.source?.setCategory(editedDoc.category)
            }
        }

        // Simpan semua perubahan ke database
        do {
            try context.save()
        } catch {
            print("❌ Gagal menyimpan: \(error.localizedDescription)")
        }
    }
}

// ============================================================
// MARK: - EditedDocument
// ============================================================
// Representasi satu dokumen yang sedang diedit.
// Ini BUKAN SwiftData @Model — hanya struct biasa di memori.

@Observable
class EditedDocument: Identifiable {

    // ID unik untuk ForEach
    let id: UUID

    // Referensi ke dokumen asli di database
    // Kita pakai ini saat saveChanges untuk menulis balik
    weak var source: DocumentModel?

    // Data yang sedang diedit user
    var name: String
    var category: DocumentCategory

    // Apakah user menandai dokumen ini untuk dihapus?
    var isMarkedForDeletion: Bool = false

    // Nilai awal untuk mendeteksi perubahan
    private let originalName: String
    private let originalCategory: DocumentCategory

    // Apakah ada perubahan pada dokumen ini?
    var hasChanges: Bool {
        name != originalName || category != originalCategory
    }

    init(source: DocumentModel) {
        self.id               = source.id
        self.source           = source
        self.name             = source.name
        self.category         = source.getCategory()
        self.originalName     = source.name
        self.originalCategory = source.getCategory()
    }
}
