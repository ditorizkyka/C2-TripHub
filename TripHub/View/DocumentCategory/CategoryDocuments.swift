//
//  CategoryDocuments.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 28/05/26.
//

import SwiftUI

struct CategoryDocuments: View {
    
    // Tangkap data dari HomeView
        var trip: TripModel
        var category: DocumentCategory
        
        // Computed property untuk memfilter dokumen
        var filteredDocuments: [DocumentModel] {
            // Ganti 'documents' dengan nama variabel relasi dokumen di dalam TripModel kamu
            trip.generalDocuments.filter { document in
                document.getCategory() == self.category
            }
        }
    let title : String
    @State private var search: String = ""
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredDocuments) { doc in
                    DocumentCardView(document: doc) {
                        // Tap → buka preview
//                        selectedDocument = doc
                        
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(title + " Documents")
    }
}

//#Preview {
//    CategoryDocuments(title: "Ticket")
//}
