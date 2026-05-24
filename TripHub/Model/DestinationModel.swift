//
//  DestinationModel.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 22/05/26.
//

import Foundation

struct DestinationModel: Identifiable {
    let id: UUID
    var name: String
    var date: Date // Harus berada di rentang tanggal Trip
    var startTime: Date // Waktu mulai
    var endTime: Date // Waktu selesai
    
    // Dokumen yang spesifik untuk destinasi ini (misal: tiket masuk wisata)
    var documents: [TripStore]
    
    init(id: UUID = UUID(), name: String, date: Date, startTime: Date, endTime: Date, documents: [TripStore] = []) {
        self.id = id
        self.name = name
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.documents = documents
    }
}
