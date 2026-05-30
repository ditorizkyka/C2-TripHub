//
//  DestinationDropdownView.swift
//  TripHub
//

import SwiftUI
import SwiftData

// MARK: - DestinationDropdownView

struct DestinationDropdownView: View {
    // MARK: - Properties
    
    @Bindable var destination: DestinationModel
    @Binding var selectedDocument: DocumentModel?
    @State private var isExpanded: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Destination Documents:")
                        .font(.helveticaCustom(size: 16))
                        .foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(destination.documents) { doc in
                                DocumentCardView(document: doc) {
                                    selectedDocument = doc
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.trailing, 20)
                    }
                    
                    if destination.documents.isEmpty {
                        Text("No documents attached.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            } label: {
                Text("Destination : \(destination.name)")
                    .font(.helveticaCustom(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color.primaryGray)
            .cornerRadius(12)
        }
    }
}
