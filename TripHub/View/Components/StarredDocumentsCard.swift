//
//  StarredDocumentsCard.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 14/05/26.
//

import SwiftUI

struct StarredDocumentsCard: View {
    let document : DocumentModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail dokumen
            documentThumbnail
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Info dokumen
            VStack(alignment: .leading, spacing: 4) {
                Text("Uploaded on \(Text(document.uploadDate.formatted(.dateTime.day().month(.wide).year())))")
                    .lineLimit(1)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(document.name)
                    .lineLimit(1)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            Spacer()
            Text(document.categoryRawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primaryGray) // Abu-abu muda sesuai branding
                .clipShape(Capsule())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1) // Border tipis
        )
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
    }
    
    // MARK: - Thumbnail View
    @ViewBuilder
    private var documentThumbnail: some View {
        if document.isImage, let image = loadImageFromDisk(fileName: document.fileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            // Ikon berwarna untuk PDF / dokumen lain
            ZStack {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: document.getCategory().icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    // Warna gradient berdasarkan kategori
    private var gradientColors: [Color] {
        switch document.getCategory() {
        case .ticket:   return [Color(hex: "#4AB855"), Color(hex: "#2d8c3e")]
        case .identity: return [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")]
        case .others:   return [Color(hex: "#EF4444"), Color(hex: "#B91C1C")]
        }
    }
    
    // Cari file gambar di seluruh subfolder Documents
    private func loadImageFromDisk(fileName: String) -> UIImage? {
        let fm = FileManager.default
        guard let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        // Coba langsung di root folder Documents
        let directURL = docsDir.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: directURL), let img = UIImage(data: data) {
            return img
        }

        // Cari di semua subfolder (struktur: TripName/DestinationName/fileName)
        if let enumerator = fm.enumerator(at: docsDir, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator {
                if url.lastPathComponent == fileName {
                    if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                        return img
                    }
                }
            }
        }

        return nil
    }
}
