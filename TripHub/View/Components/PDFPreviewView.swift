//
//  PDFPreviewView.swift
//  TripHub
//

import SwiftUI
import QuickLook

// MARK: - PDFPreviewView

struct PDFPreviewView: UIViewControllerRepresentable {
    // MARK: - Properties
    
    let document: DocumentModel

    // MARK: - Methods
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let vc = QLPreviewController()
        vc.dataSource = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(document: document)
    }

    // MARK: - Coordinator
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let document: DocumentModel

        init(document: DocumentModel) {
            self.document = document
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            findFileURL() as QLPreviewItem
        }

        private func findFileURL() -> NSURL {
            let fm = FileManager.default
            guard let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return NSURL()
            }

            let fileName = document.fileName

            let directURL = docsDir.appendingPathComponent(fileName)
            if fm.fileExists(atPath: directURL.path) { return directURL as NSURL }

            if let enumerator = fm.enumerator(at: docsDir, includingPropertiesForKeys: nil) {
                for case let url as URL in enumerator where url.lastPathComponent == fileName {
                    if fm.fileExists(atPath: url.path) { return url as NSURL }
                }
            }

            return NSURL()
        }
    }
}
