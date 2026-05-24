//
//  TripHubStorage.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 01/05/26.
//

import Foundation
import UIKit

class TripHubStorage {
    static let shared = TripHubStorage()
    
    private let fileManager = FileManager.default
    
    // Lokasi folder Documents di iPhone
    // Fungsi urls(for:in:) mengembalikan array URL, kita ambil index [0] karena hanya ada satu
    private var documentsDirectory: URL {
        let allDocumentURLs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let firstURL = allDocumentURLs[0]
        return firstURL
    }
    
    // FUNGSI SIMPAN
    // Menyimpan data (misalnya gambar) ke folder Documents dan mengembalikan nama file-nya
    func saveFile(data: Data, extension fileExtension: String) -> String? {
        // Buat nama file yang unik menggunakan UUID agar tidak bentrok dengan file lain
        let uniqueID = UUID().uuidString
        let fileName = uniqueID + "." + fileExtension

        // Tentukan lokasi lengkap file di dalam folder Documents
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        // Coba tulis data ke disk. Gunakan do-catch karena operasi ini bisa gagal
        do {
            try data.write(to: fileURL)
            // Jika berhasil, kembalikan nama file agar bisa disimpan di database
            return fileName
        } catch {
            // Jika gagal, cetak pesan error dan kembalikan nil
            print("Gagal tulis ke disk: \(error)")
            return nil
        }
    }
    
    // FUNGSI AMBIL
    // Mengubah nama file (String) menjadi URL lengkap agar bisa dibaca dari disk
    func getFilePath(fileName: String) -> URL {
        let fullURL = documentsDirectory.appendingPathComponent(fileName)
        return fullURL
    }
}
