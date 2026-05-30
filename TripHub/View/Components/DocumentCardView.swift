//
//  DocumentCardView.swift
//  TripHub
//

import SwiftUI
import SwiftData

// MARK: - DocumentCardView

struct DocumentCardView: View {
    // MARK: - Properties
    
    @Bindable var document: DocumentModel
    @Environment(\.modelContext) private var modelContext
    var onTap: () -> Void

    // MARK: - Body
    
    var body: some View {
        Button(action: { onTap() }) {
            VStack(spacing: 6) {
                DocumentThumbnailView(document: document)
                    .frame(width: thumbnailSize, height: thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .overlay(alignment: .topTrailing) {
                        if document.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.helveticaCustom(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color(hex: "#4AB855"))
                                .clipShape(Circle())
                                .offset(x: 5, y: -5)
                        }
                    }

                Text(document.name)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(height: 34, alignment: .top)

                Text(document.uploadDate, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(width: thumbnailSize)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                document.isPinned.toggle()
                try? modelContext.save()
            } label: {
                Label(
                    document.isPinned ? "Unpin" : "Pin",
                    systemImage: document.isPinned ? "pin.slash" : "pin"
                )
            }

            Divider()

            Button(role: .destructive) {
                modelContext.delete(document)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Methods
    
    private var thumbnailSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - 32 - 32) / 3
    }
}
