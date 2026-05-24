import Foundation

// ============================================================
// MARK: - LocalFileManager
// ============================================================
// Bertanggung jawab HANYA untuk urusan file fisik di storage iPhone.
// Ia tidak tahu apa itu SwiftData, ia hanya tahu folder dan file.
//
// Struktur folder yang dibuat:
//
// 📁 Documents/               ← Root folder app (bisa dilihat di Files app)
//   📁 Liburan Eropa/         ← Folder Trip
//     📄 Paspor.pdf           ← Dokumen umum trip
//     📁 Paris/               ← Folder Destinasi
//       📄 Tiket_Eiffel.pdf   ← Dokumen khusus Paris
//     📁 Roma/                ← Folder Destinasi lain
//       📄 Tiket_Colosseum.pdf
//   📁 Trip Bali/             ← Trip lain
//     ...

class LocalFileManager {

    // Singleton: satu instance untuk seluruh app
    static let shared = LocalFileManager()

    // Lokasi folder Documents milik app di iPhone
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // ============================================================
    // MARK: - Manajemen Folder
    // ============================================================

    /// Dapatkan URL folder untuk trip/destinasi tertentu.
    /// Jika folder belum ada, fungsi ini akan membuatnya otomatis.
    ///
    /// - Parameters:
    ///   - tripName: Nama trip, contoh: "Liburan Eropa"
    ///   - destinationName: (Opsional) Nama destinasi, contoh: "Paris"
    /// - Returns: URL lengkap ke folder
    func getFolderURL(tripName: String, destinationName: String? = nil) -> URL {

        // Langkah 1: Bersihkan nama (hapus karakter yang tidak valid untuk nama folder)
        let cleanTripName = tripName.sanitizedForFileName()

        // Langkah 2: Mulai dari folder Documents, lalu masuk ke subfolder trip
        var folderURL = documentsDirectory.appendingPathComponent(cleanTripName, isDirectory: true)

        // Langkah 3: Jika ada destinasi, masuk lebih dalam ke subfolder destinasi
        if let destName = destinationName, !destName.isEmpty {
            let cleanDestName = destName.sanitizedForFileName()
            folderURL = folderURL.appendingPathComponent(cleanDestName, isDirectory: true)
        }

        // Langkah 4: Buat folder jika belum ada
        createFolderIfNeeded(at: folderURL)

        return folderURL
    }

    /// Dapatkan URL lengkap file berdasarkan nama filenya dan lokasi penyimpanannya.
    ///
    /// - Parameters:
    ///   - fileName: Nama file fisik, contoh: "ABC123.pdf"
    ///   - tripName: Nama trip tempat file ini disimpan
    ///   - destinationName: (Opsional) Nama destinasi jika file ini khusus suatu destinasi
    /// - Returns: URL lengkap ke file
    func getFileURL(fileName: String, tripName: String, destinationName: String? = nil) -> URL {
        let folder = getFolderURL(tripName: tripName, destinationName: destinationName)
        return folder.appendingPathComponent(fileName)
    }

    // ============================================================
    // MARK: - Simpan File
    // ============================================================

    /// Simpan data file ke folder yang sesuai.
    ///
    /// - Parameters:
    ///   - data: Konten file dalam bentuk Data (misal: hasil dari UIImage.jpegData)
    ///   - fileName: Nama file yang akan disimpan
    ///   - tripName: Nama trip sebagai nama folder utama
    ///   - destinationName: (Opsional) Nama destinasi sebagai subfolder
    /// - Returns: URL file yang berhasil disimpan, atau nil jika gagal
    @discardableResult
    func saveDocument(
        data: Data,
        fileName: String,
        tripName: String,
        destinationName: String? = nil
    ) -> URL? {
        let folderURL = getFolderURL(tripName: tripName, destinationName: destinationName)
        let fileURL = folderURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            print("✅ File tersimpan: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("❌ Gagal menyimpan file '\(fileName)': \(error.localizedDescription)")
            return nil
        }
    }

    // ============================================================
    // MARK: - Hapus File & Folder
    // ============================================================

    /// Hapus satu file spesifik dari storage.
    func deleteDocument(fileName: String, tripName: String, destinationName: String? = nil) {
        let fileURL = getFileURL(fileName: fileName, tripName: tripName, destinationName: destinationName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ File tidak ditemukan, tidak perlu dihapus: \(fileName)")
            return
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("🗑️ File dihapus: \(fileName)")
        } catch {
            print("❌ Gagal menghapus file: \(error.localizedDescription)")
        }
    }

    /// Hapus seluruh folder trip (beserta semua isi di dalamnya).
    /// Gunakan ini saat user menghapus sebuah Trip.
    func deleteTripFolder(tripName: String) {
        let cleanName = tripName.sanitizedForFileName()
        let folderURL = documentsDirectory.appendingPathComponent(cleanName, isDirectory: true)
        deleteItemAt(url: folderURL)
        print("🗑️ Folder trip dihapus: \(cleanName)")
    }

    /// Hapus folder destinasi di dalam sebuah trip.
    /// Gunakan ini saat user menghapus sebuah Destinasi.
    func deleteDestinationFolder(tripName: String, destinationName: String) {
        let cleanTrip = tripName.sanitizedForFileName()
        let cleanDest = destinationName.sanitizedForFileName()
        let folderURL = documentsDirectory
            .appendingPathComponent(cleanTrip, isDirectory: true)
            .appendingPathComponent(cleanDest, isDirectory: true)
        deleteItemAt(url: folderURL)
        print("🗑️ Folder destinasi dihapus: \(cleanTrip)/\(cleanDest)")
    }

    // ============================================================
    // MARK: - Private Helpers
    // ============================================================

    private func createFolderIfNeeded(at url: URL) {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print("❌ Gagal membuat folder: \(error.localizedDescription)")
        }
    }

    private func deleteItemAt(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}

// ============================================================
// MARK: - String Extension
// ============================================================
// Membersihkan nama agar aman dipakai sebagai nama folder/file

private extension String {
    /// Hapus karakter yang tidak valid dalam nama folder/file
    func sanitizedForFileName() -> String {
        // Karakter yang tidak boleh ada di nama folder
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return self
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespaces)
    }
}
