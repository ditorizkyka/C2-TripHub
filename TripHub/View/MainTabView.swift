//
//  MainTabView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 11/05/26.
//

import SwiftUI

struct MainTabView: View {
    /// Deep link destination from widget tap (passed from TripHubApp)
    @Binding var deepLinkDestination: DeepLinkDestination?

    /// Set to true when the Share Extension has placed a file in the container
    @Binding var hasPendingSharedFile: Bool

    /// Tracks the currently selected tab
    @State private var selectedTab: String = "Home"

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: "Home") {
                HomeView(
                    deepLinkDestination: $deepLinkDestination,
                    hasPendingSharedFile: $hasPendingSharedFile
                )
            }

            Tab("Trip", systemImage: "airplane.up.right", value: "Trip") {
                ExploreTripView()
            }

            Tab("Documents", systemImage: "document.on.document", value: "Documents") {
                ExploreDocumentsView()
            }
        }
        .tint(Color(hex: "#4AB855"))
        .onChange(of: deepLinkDestination) { _, newValue in
            // When a widget deep link arrives, switch to the Home tab
            if newValue != nil {
                selectedTab = "Home"
            }
        }
        .onChange(of: hasPendingSharedFile) { _, newValue in
            // When a shared file arrives, switch to Home so AssignTripSheet shows
            if newValue {
                selectedTab = "Home"
            }
        }
    }
}

#Preview {
    MainTabView(
        deepLinkDestination: .constant(nil),
        hasPendingSharedFile: .constant(false)
    )
}
