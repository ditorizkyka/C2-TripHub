//
//  DocumentModel.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 24/05/26.
//

import Foundation

struct DocumentModel: Identifiable, Codable, Equatable {
    let id: UUID
    var name : String
    var uploadDate : Date
    var size : Double
    var category : DocumentCategory
    var fileName : String
    
    init(id: UUID = UUID(), name: String, uploadDate: Date = Date(), size: Double, category: DocumentCategory, fileName: String = "") {
        self.id = id
        self.name = name
        self.uploadDate = uploadDate
        self.size = size
        self.category = category
        self.fileName = fileName
    }

    
}




// Tambahkan protokol CaseIterable dan Identifiable
enum DocumentCategory: String, CaseIterable, Codable {
    case ticket = "ticket"
    case identity = "person.text.rectangle"
    case others = "document"
    
    // Syarat Identifiable: harus ada properti 'id'
    var title : String {
        switch self {
            case .ticket : return "Ticket"
            case .identity : return "Identity"
            case .others : return "Others"
            
        }
    }
    
    var icon: String {
        switch self {
        case .ticket:   return "airplane"
        case .identity: return "person.text.rectangle.fill"
        case .others:   return "doc.text.fill"
        }
    }
}
