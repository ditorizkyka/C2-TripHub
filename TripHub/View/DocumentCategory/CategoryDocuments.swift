//
//  CategoryDocuments.swift
//  TripHub
//

import SwiftUI

// MARK: - CategoryDocuments

struct CategoryDocuments: View {
    
    // MARK: - Properties
    
    @State private var selectedDocument: DocumentModel? = nil
    var trip: TripModel
    var category: DocumentCategory
    let title: String
    @State private var search: String = ""
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var filteredDocuments: [DocumentModel] {
        trip.allDocuments.filter { document in
            document.getCategory() == self.category
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            if filteredDocuments.isEmpty {
                VStack(spacing: 18) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.gray)
                    
                    VStack(spacing: 10) {
                        Text("No documents found")
                            .font(.helveticaCustom(size: 22, weight: .medium))
                            .foregroundStyle(.gray)
                        
                        Text("You haven't uploaded any documents\nthat match this filter.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredDocuments) { doc in
                        DocumentCardView(document: doc) {
                            selectedDocument = doc
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(title + " Documents")
        .sheet(item: $selectedDocument) { doc in
            DocumentPreviewView(document: doc)
        }
    }
}
