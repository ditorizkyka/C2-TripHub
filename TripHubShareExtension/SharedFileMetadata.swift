//
//  SharedFileMetadata.swift
//  TripHubShareExtension
//
//  ⚠️ This is a COPY of TripHub/Shared/SharedFileMetadata.swift
//  In Xcode, add the ORIGINAL file to both targets instead of
//  maintaining two copies. Delete this file once done.
//
//  (Keeping both copies ensures both targets compile independently.)
//

import Foundation

// ============================================================
// MARK: - SharedFileMetadata
// ============================================================

struct SharedFileMetadata: Codable {
    let fileName: String
    let isImage: Bool
    let originalName: String
}

// ============================================================
// MARK: - SharedFileManager
// ============================================================

enum SharedFileManager {

    static let appGroupID  = "group.com.ditorizkyka.TripHub"
    private static let metaKey = "pendingSharedFileMeta"

    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )
    }

    static var pendingFilesDirectory: URL? {
        guard let base = sharedContainerURL else { return nil }
        let dir = base.appendingPathComponent("PendingSharedFiles", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir, withIntermediateDirectories: true
            )
        }
        return dir
    }

    static func saveMeta(_ meta: SharedFileMetadata) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(meta) {
            defaults.set(encoded, forKey: metaKey)
            defaults.synchronize()
        }
    }

    static func loadMeta() -> SharedFileMetadata? {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data     = defaults.data(forKey: metaKey),
            let decoded  = try? JSONDecoder().decode(SharedFileMetadata.self, from: data)
        else { return nil }
        return decoded
    }

    static func clearMeta() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.removeObject(forKey: metaKey)
        defaults.synchronize()
    }

    static func fileURL(for fileName: String) -> URL? {
        pendingFilesDirectory?.appendingPathComponent(fileName)
    }

    static func loadFileData(fileName: String) -> Data? {
        guard let url = fileURL(for: fileName) else { return nil }
        return try? Data(contentsOf: url)
    }

    static func deleteFile(fileName: String) {
        guard let url = fileURL(for: fileName) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
