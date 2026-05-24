//
//  TripHubApp.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 30/04/26.
//

import SwiftUI
import SwiftData

@main
struct TripHubApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
            TripModel.self,
            DestinationModel.self,
            DocumentModel.self,
        ])
    }
}
