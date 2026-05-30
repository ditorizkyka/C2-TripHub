//
//  ShareViewController.swift
//  TripHubShareExtension
//
//  Created by Andito Rizkyka Rianto on 30/05/26.
//
//  Flow:
//  1. User taps "TripHub" in the iOS Share Sheet
//  2. This controller receives the file (PDF or image)
//  3. Copies it to the App Group shared container
//  4. Writes metadata (fileName, isImage, originalName) to shared UserDefaults
//  5. Opens the main TripHub app via triphub://share
//  6. Closes the extension

import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Show a simple loading indicator while we process the file
        view.backgroundColor = UIColor.systemBackground
        let activity = UIActivityIndicatorView(style: .large)
        activity.translatesAutoresizingMaskIntoConstraints = false
        activity.startAnimating()
        view.addSubview(activity)
        NSLayoutConstraint.activate([
            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Start processing the shared item
        handleSharedItem()
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Main Handler
    // ─────────────────────────────────────────────────────────────

    private func handleSharedItem() {
        guard
            let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
            let attachments   = extensionItem.attachments,
            !attachments.isEmpty
        else {
            completeRequest(success: false)
            return
        }

        let provider = attachments[0]

        // ── Priority 1: PDF ──────────────────────────────────────
        let pdfType = UTType.pdf.identifier   // "com.adobe.pdf"
        if provider.hasItemConformingToTypeIdentifier(pdfType) {
            provider.loadItem(forTypeIdentifier: pdfType, options: nil) { [weak self] item, error in
                guard let self else { return }
                if let url = item as? URL {
                    self.saveFile(sourceURL: url, isImage: false)
                } else if let data = item as? Data {
                    self.saveData(data, isImage: false, hint: "document.pdf")
                } else {
                    self.completeRequest(success: false)
                }
            }
            return
        }

        // ── Priority 2: Image ────────────────────────────────────
        let imageType = UTType.image.identifier   // "public.image"
        if provider.hasItemConformingToTypeIdentifier(imageType) {
            provider.loadItem(forTypeIdentifier: imageType, options: nil) { [weak self] item, error in
                guard let self else { return }
                if let url = item as? URL {
                    self.saveFile(sourceURL: url, isImage: true)
                } else if let data = item as? Data {
                    self.saveData(data, isImage: true, hint: "image.jpg")
                } else if let image = item as? UIImage,
                          let jpeg = image.jpegData(compressionQuality: 0.8) {
                    self.saveData(jpeg, isImage: true, hint: "image.jpg")
                } else {
                    self.completeRequest(success: false)
                }
            }
            return
        }

        // ── Priority 3: Generic file URL ─────────────────────────
        let fileURLType = UTType.fileURL.identifier   // "public.file-url"
        if provider.hasItemConformingToTypeIdentifier(fileURLType) {
            provider.loadItem(forTypeIdentifier: fileURLType, options: nil) { [weak self] item, error in
                guard let self else { return }
                if let url = item as? URL {
                    let isImage = UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) ?? false
                    self.saveFile(sourceURL: url, isImage: isImage)
                } else {
                    self.completeRequest(success: false)
                }
            }
            return
        }

        // Nothing matched
        completeRequest(success: false)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - Save Helpers
    // ─────────────────────────────────────────────────────────────

    /// Copy a file URL into the App Group pending directory
    private func saveFile(sourceURL: URL, isImage: Bool) {
        let ext          = sourceURL.pathExtension.isEmpty ? (isImage ? "jpg" : "pdf") : sourceURL.pathExtension
        let uniqueName   = "\(UUID().uuidString).\(ext)"
        let originalName = sourceURL.deletingPathExtension().lastPathComponent

        guard let destURL = SharedFileManager.fileURL(for: uniqueName) else {
            completeRequest(success: false)
            return
        }

        // The source URL may be security-scoped — try to access it
        let didStart = sourceURL.startAccessingSecurityScopedResource()
        defer { if didStart { sourceURL.stopAccessingSecurityScopedResource() } }

        do {
            // If destination already exists, remove it first
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            print("❌ ShareExtension: copy failed: \(error.localizedDescription)")
            completeRequest(success: false)
            return
        }

        let meta = SharedFileMetadata(
            fileName:     uniqueName,
            isImage:      isImage,
            originalName: originalName
        )
        SharedFileManager.saveMeta(meta)
        openMainApp()
    }

    /// Save raw Data directly into the App Group pending directory
    private func saveData(_ data: Data, isImage: Bool, hint: String) {
        let ext          = (hint as NSString).pathExtension
        let uniqueName   = "\(UUID().uuidString).\(ext)"
        let originalName = (hint as NSString).deletingPathExtension

        guard let destURL = SharedFileManager.fileURL(for: uniqueName) else {
            completeRequest(success: false)
            return
        }

        do {
            try data.write(to: destURL)
        } catch {
            print("❌ ShareExtension: write failed: \(error.localizedDescription)")
            completeRequest(success: false)
            return
        }

        let meta = SharedFileMetadata(
            fileName:     uniqueName,
            isImage:      isImage,
            originalName: originalName
        )
        SharedFileManager.saveMeta(meta)
        openMainApp()
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: - App Launch & Completion
    // ─────────────────────────────────────────────────────────────

    /// Open the main TripHub app so it shows AssignTripSheet
    private func openMainApp() {
        guard let url = URL(string: "triphub://share") else {
            completeRequest(success: true)
            return
        }

        // Walk up the responder chain to find a UIApplication
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url, options: [:]) { [weak self] _ in
                    self?.completeRequest(success: true)
                }
                return
            }
            responder = r.next
        }

        // Fallback: complete without opening (app will still detect via UserDefaults on next launch)
        completeRequest(success: true)
    }

    private func completeRequest(success: Bool) {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
