//
//  ImageFullView.swift
//  TripHub
//

import SwiftUI

// MARK: - ImageFullView

struct ImageFullView: View {
    // MARK: - Properties
    
    let document: DocumentModel
    @State private var scale: CGFloat = 1.0

    // MARK: - Body
    
    var body: some View {
        Group {
            if let image = findImage(fileName: document.fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in scale = max(1.0, value) }
                            .onEnded   { _ in withAnimation { scale = 1.0 } }
                    )
                    .padding()
            } else {
                ContentUnavailableView(
                    "Image not found",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("File may have been deleted or moved.")
                )
            }
        }
    }

    // MARK: - Methods
    
    private func findImage(fileName: String) -> UIImage? {
        let fm = FileManager.default
        guard let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }

        let direct = docsDir.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: direct), let img = UIImage(data: data) { return img }

        if let enumerator = fm.enumerator(at: docsDir, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator where url.lastPathComponent == fileName {
                if let data = try? Data(contentsOf: url), let img = UIImage(data: data) { return img }
            }
        }
        return nil
    }
}
