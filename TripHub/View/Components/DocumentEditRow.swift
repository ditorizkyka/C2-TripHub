//
//  DocumentEditRow.swift
//  TripHub
//

import SwiftUI

// MARK: - DocumentEditRow

struct DocumentEditRow: View {
    // MARK: - Properties
    
    @Bindable var editedDoc: EditedDocument

    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                Image(systemName: editedDoc.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Document Name", text: $editedDoc.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("Category", selection: $editedDoc.category) {
                    ForEach(DocumentCategory.allCases, id: \.self) { cat in
                        Label(cat.title, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                .foregroundColor(.secondary)
                .labelsHidden()
                .padding(.leading, -8)
            }

            Spacer()

            Button {
                editedDoc.isMarkedForDeletion = true
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.vertical, 10)
        .background(
            editedDoc.hasChanges
            ? Color.orange.opacity(0.05)
            : Color.clear
        )
    }

    // MARK: - Methods

    private var iconColor: Color {
        switch editedDoc.category {
        case .ticket:   return .blue
        case .identity: return .purple
        case .others:   return .orange
        }
    }

    private var iconBackground: Color {
        iconColor.opacity(0.15)
    }
}
