//
//  EditCard.swift
//  TripHub
//

import SwiftUI

// MARK: - EditCard

struct EditCard<Content: View>: View {
    // MARK: - Properties
    
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.leading, 5)

            VStack(alignment: .leading) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .padding(.horizontal)
    }
}
