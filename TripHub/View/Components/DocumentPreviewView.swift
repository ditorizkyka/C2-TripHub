//
//  DocumentPreviewView.swift
//  TripHub
//

import SwiftUI

// MARK: - DocumentPreviewView

struct DocumentPreviewView: View {
    // MARK: - Properties
    
    let document: DocumentModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if document.isImage {
                    ImageFullView(document: document)
                } else {
                    PDFPreviewView(document: document)
                }
            }
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: "#4AB855"))
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
