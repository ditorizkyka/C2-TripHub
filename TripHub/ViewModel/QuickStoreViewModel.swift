import SwiftUI
import PhotosUI
import SwiftData

// ============================================================
// MARK: - PendingDocument
// ============================================================
// Model SEMENTARA untuk file yang belum disimpan.
// Hanya hidup di memori selama user mengisi form.
// Setelah user tekan "Simpan", kita ubah ini jadi DocumentModel.

struct PendingDocument: Identifiable {
    let id = UUID()
    var isImage: Bool          // true = gambar, false = PDF
    var imageData: Data?       // Data gambar (sudah di-convert ke JPEG bytes)
    var pdfData: Data?         // Data PDF (sudah di-copy ke memori)
    var name: String           // Nama tampilan yang bisa diubah user
    var category: DocumentCategory = .others
}


// ============================================================
// MARK: - QuickStoreViewModel
// ============================================================
// ViewModel ini mengelola semua state dan logika untuk form "Quick Store".
//
// Tugasnya:
// 1. Menyimpan state form (nama trip, tanggal, destinasi, dokumen pending)
// 2. Memproses file yang dipilih (dari Photos/PDF picker)
// 3. Menyimpan semuanya ke disk + SwiftData saat user klik "Simpan"

@MainActor
@Observable
class QuickStoreViewModel {

    // --- State: Informasi Trip ---
    var searchText: String = ""
    var selectedTrip: TripModel? = nil
    var startDate = Date()
    var isRangeEnabled = false
    var durationDays = 1

    // Deskripsi opsional yang bisa diisi user saat membuat trip baru
    var tripDescription: String = ""

    // Data foto sampul yang dipilih dari Photos picker (opsional)
    var coverImageData: Data? = nil

    // Tanggal akhir dihitung otomatis
    var endDate: Date {
        return Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
    }

    // --- State: Destinasi ---
    var destinationName: String = ""
    var destinationStartDate = Date()
    var destinationEndDate = Date()
    var newDestinations: [DestinationModel] = []
    var selectedDestinationId: UUID? = nil

    // --- State: Dokumen yang Belum Disimpan ---
    var pendingDocuments: [PendingDocument] = []

    // PhotosPicker butuh binding ke array ini
    var selectedItems: [PhotosPickerItem] = [] {
        didSet {
            // Jangan proses jika kosong
            if selectedItems.isEmpty { return }

            // Simpan dulu item yang mau diproses
            let itemsToProcess = selectedItems

            // Kosongkan segera agar picker bisa dipilih lagi
            DispatchQueue.main.async {
                self.selectedItems = []
            }

            // Mulai proses gambar
            loadImages(itemsToProcess)
        }
    }

    // --- State: UI ---
    var isSaving = false
    var showSaveSuccess = false

    // Jumlah total file yang siap disimpan
    var totalFileCount: Int {
        return pendingDocuments.count
    }

    // Tombol "Simpan" hanya aktif jika ada nama trip DAN minimal 1 dokumen
    var canSave: Bool {
        let hasTrip = selectedTrip != nil || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        let hasDocs = !pendingDocuments.isEmpty
        return hasTrip && hasDocs
    }

    // ============================================================
    // MARK: - SIMPAN TRIP (Fungsi Utama)
    // ============================================================
    // Dipanggil saat user menekan tombol "Simpan".
    //
    // PENTING untuk SwiftData:
    // - Jangan set KEDUA sisi relasi sekaligus!
    //   Contoh salah: doc.trip = trip DAN trip.generalDocuments.append(doc)
    //   Contoh benar: doc.trip = trip (SwiftData otomatis update sisi lainnya)

    func saveTrip(modelContext: ModelContext) {
        isSaving = true

        // --- Tentukan nama trip ---
        let tripName: String
        if let existing = selectedTrip {
            tripName = existing.name
        } else {
            tripName = searchText.trimmingCharacters(in: .whitespaces)
        }

        // Validasi: nama trip tidak boleh kosong
        if tripName.isEmpty {
            print("⚠️ Nama trip kosong, batal simpan.")
            isSaving = false
            return
        }

        // --- Tentukan tanggal akhir ---
        let finalEndDate: Date
        if isRangeEnabled {
            finalEndDate = endDate
        } else {
            finalEndDate = startDate
        }

        // ============================================
        // LANGKAH 1: Tentukan trip target
        // ============================================
        let tripTarget: TripModel

        if let existing = selectedTrip {
            // User memilih trip yang sudah ada
            tripTarget = existing
        } else {
            // Buat trip baru — sertakan description dan cover image jika diisi
            let desc = tripDescription.trimmingCharacters(in: .whitespaces)
            let newTrip = TripModel(
                name: tripName,
                startDate: startDate,
                endDate: finalEndDate,
                tripDescription: desc.isEmpty ? nil : desc,
                coverImageData: coverImageData
            )
            modelContext.insert(newTrip)
            tripTarget = newTrip
        }

        // ============================================
        // LANGKAH 2: Tambah destinasi baru (jika ada)
        // ============================================
        for dest in newDestinations {
            modelContext.insert(dest)
            // Cukup set SATU sisi relasi saja!
            // SwiftData otomatis menambahkan dest ke trip.destinations
            dest.trip = tripTarget
        }

        // ============================================
        // LANGKAH 3: Tentukan target destinasi (jika dipilih)
        // ============================================
        var targetDestination: DestinationModel? = nil
        var targetDestinationName: String? = nil

        if let destId = selectedDestinationId {
            // Cek di destinasi yang sudah ada di trip
            if let found = tripTarget.destinations.first(where: { $0.id == destId }) {
                targetDestination = found
                targetDestinationName = found.name
            }
            // Cek di destinasi baru yang baru ditambah di form ini
            if targetDestination == nil {
                if let found = newDestinations.first(where: { $0.id == destId }) {
                    targetDestination = found
                    targetDestinationName = found.name
                }
            }
        }

        // ============================================
        // LANGKAH 4: Simpan setiap dokumen
        // ============================================
        for (index, pendingDoc) in pendingDocuments.enumerated() {

            // --- Tentukan ekstensi file ---
            let fileExtension: String
            if pendingDoc.isImage {
                fileExtension = "jpg"
            } else {
                fileExtension = "pdf"
            }

            // --- Buat nama file unik ---
            let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"

            // --- Tentukan nama tampilan ---
            let displayName: String
            let trimmedName = pendingDoc.name.trimmingCharacters(in: .whitespaces)
            if trimmedName.isEmpty {
                displayName = "\(tripName)_doc_\(index + 1)"
            } else {
                displayName = trimmedName
            }

            // --- Ambil data file ---
            let fileData: Data?
            if pendingDoc.isImage {
                fileData = pendingDoc.imageData
            } else {
                fileData = pendingDoc.pdfData
            }

            // Lewati jika data kosong
            guard let data = fileData else {
                print("⚠️ Lewati '\(displayName)': data kosong")
                continue
            }

            // --- Simpan file fisik ke folder ---
            LocalFileManager.shared.saveDocument(
                data: data,
                fileName: uniqueFileName,
                tripName: tripName,
                destinationName: targetDestinationName
            )

            // --- Hitung ukuran file (dalam MB) ---
            let fileSizeMB = Double(data.count) / (1024.0 * 1024.0)

            // --- Buat metadata di SwiftData ---
            let newDoc = DocumentModel(
                name: displayName,
                uploadDate: Date(),
                size: fileSizeMB,
                category: pendingDoc.category,
                fileName: uniqueFileName
            )
            modelContext.insert(newDoc)

            // --- Hubungkan dokumen ke trip atau destinasi ---
            // PENTING: Set SATU sisi saja! Jangan dua-duanya!
            if let dest = targetDestination {
                // Dokumen masuk ke destinasi tertentu
                newDoc.destination = dest
            } else {
                // Dokumen masuk ke folder umum trip
                newDoc.trip = tripTarget
            }
        }

        // ============================================
        // LANGKAH 5: Simpan semua perubahan ke database
        // ============================================
        do {
            try modelContext.save()
            print("✅ Semua data berhasil disimpan!")
        } catch {
            print("❌ Gagal menyimpan ke database: \(error.localizedDescription)")
        }

        // ============================================
        // LANGKAH 6: Bersihkan form
        // ============================================
        resetForm()
        isSaving = false
        showSaveSuccess = true
    }


    // ============================================================
    // MARK: - Proses Gambar dari Photos Picker
    // ============================================================

    private func loadImages(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    switch result {
                    case .success(let data):
                        guard let data = data else {
                            print("⚠️ Data gambar nil, lewati.")
                            return
                        }
                        guard let image = UIImage(data: data) else {
                            print("⚠️ Tidak bisa membuat UIImage dari data.")
                            return
                        }

                        // Langsung convert ke JPEG data dan simpan di memori
                        // Ini mencegah crash karena UIImage bisa hilang dari memori
                        let jpegData = image.jpegData(compressionQuality: 0.8)

                        let docName = "Image_\(self.pendingDocuments.count + 1)"
                        let newDoc = PendingDocument(
                            isImage: true,
                            imageData: jpegData,
                            pdfData: nil,
                            name: docName
                        )
                        self.pendingDocuments.append(newDoc)

                    case .failure(let error):
                        print("❌ Gagal memuat gambar: \(error.localizedDescription)")
                    }
                }
            }
        }
    }


    // ============================================================
    // MARK: - Reset Form
    // ============================================================

    func resetForm() {
        searchText = ""
        selectedTrip = nil
        startDate = Date()
        isRangeEnabled = false
        durationDays = 1
        tripDescription = ""
        coverImageData = nil
        destinationName = ""
        newDestinations = []
        destinationStartDate = Date()
        destinationEndDate = Date()
        selectedDestinationId = nil
        pendingDocuments = []
    }
}
