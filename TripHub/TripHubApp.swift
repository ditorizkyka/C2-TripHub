//
//  TripHubApp.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 30/04/26.
//

import SwiftUI
import SwiftData

// ============================================================
// MARK: - Deep Link Destination
// ============================================================
// Enum representing where a URL scheme should navigate to.

enum DeepLinkDestination: Equatable {
    case ticket
    case identity
    case others
    /// Triggered when the Share Extension passes a file to the app
    case share

    /// Parse a URL like "triphub://category/ticket" or "triphub://share"
    init?(url: URL) {
        guard url.scheme == "triphub" else { return nil }

        // Handle "triphub://share"
        if url.host == "share" {
            self = .share
            return
        }

        // Handle "triphub://category/ticket" and "triphub://ticket"
        let pathOrHost: String
        if url.host == "category" {
            pathOrHost = url.pathComponents.dropFirst().first ?? ""
        } else {
            pathOrHost = url.host ?? ""
        }

        switch pathOrHost {
        case "ticket":   self = .ticket
        case "identity": self = .identity
        case "others":   self = .others
        default:         return nil
        }
    }

    /// Convert to DocumentCategory for navigation
    var documentCategory: String {
        switch self {
        case .ticket:   return "Ticket"
        case .identity: return "Identity"
        case .others:   return "Others"
        case .share:    return ""
        }
    }
}

// ============================================================
// MARK: - App Entry Point
// ============================================================

@main
struct TripHubApp: App {
    /// Deep link destination (from widget tap or share extension)
    @State private var deepLinkDestination: DeepLinkDestination?

    /// Set to true when a shared file is waiting to be assigned to a trip
    @State private var hasPendingSharedFile: Bool = false

    var body: some Scene {
        WindowGroup {
            MainTabView(
                deepLinkDestination: $deepLinkDestination,
                hasPendingSharedFile: $hasPendingSharedFile
            )
            .onOpenURL { url in
                let dest = DeepLinkDestination(url: url)
                if dest == .share {
                    // Share extension sent a file — tell HomeView to show the sheet
                    hasPendingSharedFile = true
                } else {
                    deepLinkDestination = dest
                }
            }
            // Also check on app launch (in case the user had previously shared
            // a file but the app wasn't running yet)
            .onAppear {
                if SharedFileManager.loadMeta() != nil {
                    hasPendingSharedFile = true
                }
            }
        }
        .modelContainer(for: [
            TripModel.self,
            DestinationModel.self,
            DocumentModel.self,
        ])
    }
}
