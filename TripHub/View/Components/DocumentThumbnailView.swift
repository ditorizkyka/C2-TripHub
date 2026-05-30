//
//  DocumentThumbnailView.swift
//  TripHub
//

import SwiftUI

// MARK: - DocumentThumbnailView

struct DocumentThumbnailView: View {
    // MARK: - Properties
    
    let document: DocumentModel

    // MARK: - Body
    
    var body: some View {
        if document.isImage, let image = loadImageFromDisk(fileName: document.fileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.white.opacity(0.9))

                    Text(fileExtension.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Methods
    
    private var fileExtension: String {
        (document.fileName as NSString).pathExtension
    }

    private var iconName: String {
        switch document.getCategory() {
        case .ticket:   return "airplane.circle"
        case .identity: return "person.text.rectangle"
        case .others:   return "doc.richtext"
        }
    }

    private var gradientColors: [Color] {
        switch document.getCategory() {
        case .ticket:   return [Color(hex: "#4AB855"), Color(hex: "#2d8c3e")]
        case .identity: return [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")]
        case .others:   return [Color(hex: "#EF4444"), Color(hex: "#B91C1C")]
        }
    }

    private func loadImageFromDisk(fileName: String) -> UIImage? {
        let fm = FileManager.default
        guard let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let directURL = docsDir.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: directURL), let img = UIImage(data: data) {
            return img
        }

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
