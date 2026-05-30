//
//  SwipeablePendingDocRow.swift
//  TripHub
//

import SwiftUI

// MARK: - SwipeablePendingDocRow

struct SwipeablePendingDocRow: View {
    // MARK: - Properties
    
    @Binding var document: PendingDocument
    var onDelete: () -> Void
    @State private var offset: CGFloat = 0

    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onDelete) {
                VStack {
                    Image(systemName: "trash")
                        .font(.title3)
                    Text("Delete")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 75)
                .frame(maxHeight: .infinity)
                .background(Color.red)
                .cornerRadius(8)
            }
            .padding(.trailing, 2)
            
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(document.isImage ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: document.isImage ? "photo" : "doc.fill")
                        .foregroundColor(document.isImage ? .blue : .green)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.name)
                        .font(.helveticaCustom(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    Picker("Category", selection: $document.category) {
                        ForEach(DocumentCategory.allCases, id: \.self) { cat in
                            Text(cat.title).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .font(.helveticaCustom(size: 8, weight: .medium))
                    .tint(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primaryGray)
                    .cornerRadius(6)
                }
                
                Spacer()
            }
            .padding(10)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width < -50 {
                                offset = -75
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
    }
}
