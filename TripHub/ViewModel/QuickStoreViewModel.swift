import SwiftUI
import PhotosUI
import SwiftData

// ============================================================
// MARK: - PendingDocument
// ============================================================
// Ini adalah model SEMENTARA untuk dokumen yang belum disimpan.
// Dokumen "pending" ini hanya ada di memori selama user mengisi form.
// Setelah user tekan "Simpan", baru kita ubah ini jadi DocumentModel yang tersimpan permanen.

struct PendingDocument: Identifiable {
    let id = UUID()
    var isImage: Bool          // true = gambar, false = PDF
    var image: UIImage?        // Isi gambar jika isImage == true
    var pdfURL: URL?           // URL file PDF jika isImage == false
    var name: String           // Nama tampilan yang bisa diubah user
    var category: DocumentCategory = .others  // Kategori yang dipilih user
}


// ============================================================
// MARK: - QuickStoreViewModel
// ============================================================
// ViewModel ini mengelola semua state dan logika untuk form "Quick Store".
// Tugasnya adalah:
// 1. Menyimpan state form (nama trip, tanggal, destinasi, dokumen pending)
// 2. Memproses dokumen yang dipilih (ambil dari Photos/PDF picker)
// 3. Menyimpan semuanya ke disk (file fisik) dan SwiftData (metadata) saat user klik "Simpan"

@MainActor
@Observable
class QuickStoreViewModel {

    // --- State: Informasi Trip ---
    var searchText: String = ""          // Teks yang diketik di field pencarian trip
    var selectedTrip: TripModel? = nil   // Trip yang sudah dipilih (dari daftar yang ada)
    var startDate = Date()
    var isRangeEnabled = false           // Apakah trip punya durasi (lebih dari 1 hari)?
    var durationDays = 1                 // Berapa hari tripnya?

    // Tanggal akhir dihitung otomatis dari startDate + durationDays
    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
    }

    // --- State: Destinasi ---
    var destinationName: String = ""
    var destinationStartDate = Date()
    var destinationEndDate = Date()
    var destinations: [DestinationModel] = []       // Destinasi BARU yang ditambah di form ini
    var selectedDestinationId: UUID? = nil          // Destinasi yang dipilih sebagai target upload

    // --- State: Dokumen yang Belum Disimpan ---
    var pendingDocuments: [PendingDocument] = []

    // PhotosPicker membutuhkan binding ke array ini
    var selectedItems: [PhotosPickerItem] = [] {
        didSet {
            guard !selectedItems.isEmpty else { return }
            let itemsToProcess = selectedItems

            // Reset array segera agar picker bisa dipilih lagi
            DispatchQueue.main.async {
                self.selectedItems = []
            }

            // Proses gambar yang dipilih
            loadImages(itemsToProcess)
        }
    }

    // --- State: UI ---
    var isSaving = false
    var showSaveSuccess = false
    var errorMessage: String? = nil   // Tampilkan error jika ada yang gagal

    // Jumlah total file yang siap disimpan
    var totalFileCount: Int {
        pendingDocuments.count
    }

    // Tombol "Simpan" hanya aktif jika ada nama trip dan minimal 1 dokumen
    var canSave: Bool {
        let tripName = selectedTrip?.name ?? searchText.trimmingCharacters(in: .whitespaces)
        return !tripName.isEmpty && !pendingDocuments.isEmpty
    }


    // ============================================================
    // MARK: - Simpan Trip (Fungsi Utama)
    // ============================================================
    // Fungsi ini dipanggil saat user menekan tombol "Simpan".
    // Ia perlu `modelContext` dari SwiftData untuk menyimpan data ke database.

    func saveTrip(modelContext: ModelContext) {
        isSaving = true
        errorMessage = nil

        // Tentukan nama trip (dari yang sudah dipilih, atau dari teks yang diketik)
        let tripName = selectedTrip?.name ?? searchText.trimmingCharacters(in: .whitespaces)
        guard !tripName.isEmpty else {
            errorMessage = "Nama trip tidak boleh kosong."
            isSaving = false
            return
        }

        // Tentukan tanggal akhir berdasarkan apakah user aktifkan toggle durasi
        let actualEndDate: Date = isRangeEnabled ? endDate : startDate

        // ----------------------------------------
        // LANGKAH 1: Simpan file fisik ke disk
        //            dan buat objek DocumentModel untuk setiap file
        // ----------------------------------------
        var newDocuments: [DocumentModel] = []

        for (index, pendingDoc) in pendingDocuments.enumerated() {

            // Tentukan ekstensi file
            let fileExtension = pendingDoc.isImage ? "jpg" : "pdf"

            // Buat nama file unik menggunakan UUID agar tidak pernah bentrok
            let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"

            // Tentukan nama tampilan (jika user tidak mengisi, buat nama otomatis)
            let displayName = pendingDoc.name.trimmingCharacters(in: .whitespaces).isEmpty
                ? "\(tripName)_doc_\(index + 1)"
                : pendingDoc.name

            // Ambil data (bytes) dari file
            var fileData: Data? = nil
            if pendingDoc.isImage, let image = pendingDoc.image {
                fileData = image.jpegData(compressionQuality: 0.8)
            } else if let pdfURL = pendingDoc.pdfURL {
                fileData = try? Data(contentsOf: pdfURL)
            }

            // Jika berhasil mendapat data, simpan ke disk
            guard let data = fileData else {
                print("⚠️ Melewati dokumen '\(displayName)': data tidak bisa dibaca.")
                continue
            }

            // Tentukan destinasi penyimpanan file
            // (di folder umum trip, atau di subfolder destinasi tertentu)
            let targetDestinationName = getSelectedDestinationName()

            // Simpan file fisik ke folder yang sesuai
            LocalFileManager.shared.saveDocument(
                data: data,
                fileName: uniqueFileName,
                tripName: tripName,
                destinationName: targetDestinationName
            )

            // Hitung ukuran file dalam MB
            let fileSizeMB = Double(data.count) / (1024.0 * 1024.0)

            // Buat objek metadata (DocumentModel) untuk database SwiftData
            let newDoc = DocumentModel(
                name: displayName,
                uploadDate: Date(),
                size: fileSizeMB,
                category: pendingDoc.category,
                fileName: uniqueFileName
            )
            newDocuments.append(newDoc)
        }

        // ----------------------------------------
        // LANGKAH 2: Simpan ke SwiftData
        //            (tambah ke trip yang ada, atau buat trip baru)
        // ----------------------------------------
        if let existingTrip = selectedTrip {
            // --- Update trip yang sudah ada ---
            addDocumentsToExistingTrip(
                trip: existingTrip,
                newDocuments: newDocuments,
                modelContext: modelContext
            )
        } else {
            // --- Buat trip baru ---
            createNewTrip(
                name: tripName,
                startDate: startDate,
                endDate: actualEndDate,
                newDocuments: newDocuments,
                modelContext: modelContext
            )
        }

        // ----------------------------------------
        // LANGKAH 3: Reset form dan tampilkan sukses
        // ----------------------------------------
        resetForm()
        isSaving = false
        showSaveSuccess = true
    }


    // ============================================================
    // MARK: - Private: Ambil Gambar dari Photos Picker
    // ============================================================

    private func loadImages(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    switch result {
                    case .success(let data):
                        if let data = data, let image = UIImage(data: data) {
                            let docName = "Image_\(self.pendingDocuments.count + 1)"
                            let newDoc = PendingDocument(
                                isImage: true,
                                image: image,
                                pdfURL: nil,
                                name: docName
                            )
                            self.pendingDocuments.append(newDoc)
                        }
                    case .failure(let error):
                        print("❌ Gagal memuat gambar: \(error.localizedDescription)")
                    }
                }
            }
        }
    }


    // ============================================================
    // MARK: - Private: Helpers Penyimpanan SwiftData
    // ============================================================

    /// Dapatkan nama destinasi yang sedang dipilih (untuk menentukan subfolder)
    private func getSelectedDestinationName() -> String? {
        guard let destId = selectedDestinationId else { return nil }

        // Cek di destinasi dari existing trip
        if let existingTrip = selectedTrip,
           let dest = existingTrip.destinations.first(where: { $0.id == destId }) {
            return dest.name
        }

        // Cek di destinasi baru yang baru saja ditambahkan di form ini
        if let dest = destinations.first(where: { $0.id == destId }) {
            return dest.name
        }

        return nil
    }

    /// Tambah dokumen ke trip yang sudah ada di database
    private func addDocumentsToExistingTrip(
        trip: TripModel,
        newDocuments: [DocumentModel],
        modelContext: ModelContext
    ) {
        // Masukkan semua dokumen baru ke SwiftData context dulu
        for doc in newDocuments {
            modelContext.insert(doc)
        }

        // Masukkan semua destinasi baru ke SwiftData context dulu
        for dest in destinations {
            modelContext.insert(dest)
            dest.trip = trip
            trip.destinations.append(dest)
        }

        // Distribusikan dokumen ke lokasi yang tepat
        if let destId = selectedDestinationId {
            // User memilih destinasi tertentu → masuk ke dokumen destinasi itu
            if let dest = trip.destinations.first(where: { $0.id == destId }) {
                for doc in newDocuments {
                    doc.destination = dest
                    dest.documents.append(doc)
                }
            } else if let dest = destinations.first(where: { $0.id == destId }) {
                for doc in newDocuments {
                    doc.destination = dest
                    dest.documents.append(doc)
                }
            }
        } else {
            // Tidak ada destinasi dipilih → masuk ke dokumen umum trip
            for doc in newDocuments {
                doc.trip = trip
                trip.generalDocuments.append(doc)
            }
        }

        try? modelContext.save()
    }

    /// Buat trip baru dan simpan ke database
    private func createNewTrip(
        name: String,
        startDate: Date,
        endDate: Date,
        newDocuments: [DocumentModel],
        modelContext: ModelContext
    ) {
        // Buat objek trip baru
        let newTrip = TripModel(name: name, startDate: startDate, endDate: endDate)
        modelContext.insert(newTrip)

        // Masukkan semua dokumen baru ke SwiftData context
        for doc in newDocuments {
            modelContext.insert(doc)
        }

        // Masukkan semua destinasi baru ke SwiftData context
        for dest in destinations {
            modelContext.insert(dest)
            dest.trip = newTrip
            newTrip.destinations.append(dest)
        }

        // Distribusikan dokumen ke lokasi yang tepat
        if let destId = selectedDestinationId,
           let dest = destinations.first(where: { $0.id == destId }) {
            // Dokumen masuk ke destinasi tertentu
            for doc in newDocuments {
                doc.destination = dest
                dest.documents.append(doc)
            }
        } else {
            // Dokumen masuk ke folder umum trip
            for doc in newDocuments {
                doc.trip = newTrip
                newTrip.generalDocuments.append(doc)
            }
        }

        try? modelContext.save()
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
        destinationName = ""
        destinations = []
        destinationStartDate = Date()
        destinationEndDate = Date()
        selectedDestinationId = nil
        pendingDocuments = []
    }
}
