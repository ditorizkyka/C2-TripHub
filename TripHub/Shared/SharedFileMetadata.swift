//
//  SharedFileMetadata.swift
//  TripHub
//
//  ⚠️ Add this file to BOTH targets in Xcode:
//     - TripHub (main app)
//     - TripHubShareExtension
//

import Foundation

// ============================================================
// MARK: - SharedFileMetadata
// ============================================================
// Lightweight info written by the Share Extension to UserDefaults
// so the main app knows what file is waiting in the container.

struct SharedFileMetadata: Codable {
    /// Name of the file saved in the App Group container
    /// e.g. "ABC123-uuid.pdf" or "ABC123-uuid.jpg"
    let fileName: String

    /// true = image (JPEG/PNG/HEIC), false = PDF
    let isImage: Bool

    /// Original file name or suggested display name
    let originalName: String
}

// ============================================================
// MARK: - SharedFileManager
// ============================================================
// Reads / writes / clears the pending shared-file queue
// via the App Group shared UserDefaults.

enum SharedFileManager {

    static let appGroupID   = "group.com.ditorizkyka.TripHub"
    private static let metaKey  = "pendingSharedFileMeta"

    // ── App Group Container ─────────────────────────────────
    /// Root folder inside the App Group container where the
    /// Share Extension drops incoming files.
    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )
    }

    /// Subfolder inside the container used for pending shared files
    static var pendingFilesDirectory: URL? {
        guard let base = sharedContainerURL else { return nil }
        let dir = base.appendingPathComponent("PendingSharedFiles", isDirectory: true)
        // Create if not yet present
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir, withIntermediateDirectories: true
            )
        }
        return dir
    }

    // ── Metadata helpers ────────────────────────────────────
    /// Save metadata so the main app knows a file is waiting
    static func saveMeta(_ meta: SharedFileMetadata) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(meta) {
            defaults.set(encoded, forKey: metaKey)
            defaults.synchronize()
        }
    }

    /// Read the pending metadata (called by the main app on launch/foreground)
    static func loadMeta() -> SharedFileMetadata? {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data     = defaults.data(forKey: metaKey),
            let decoded  = try? JSONDecoder().decode(SharedFileMetadata.self, from: data)
        else { return nil }
        return decoded
    }

    /// Clear the pending metadata after the main app has consumed it
    static func clearMeta() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.removeObject(forKey: metaKey)
        defaults.synchronize()
    }

    // ── File helpers ────────────────────────────────────────
    /// Full URL for a file in the pending directory
    static func fileURL(for fileName: String) -> URL? {
        pendingFilesDirectory?.appendingPathComponent(fileName)
    }

    /// Read the file data from the App Group container
    static func loadFileData(fileName: String) -> Data? {
        guard let url = fileURL(for: fileName) else { return nil }
        return try? Data(contentsOf: url)
    }

    /// Delete the file from the container after it has been consumed
    static func deleteFile(fileName: String) {
        guard let url = fileURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
