//
//  FormCard.swift
//  TripHub
//

import SwiftUI

// MARK: - FormCard

struct FormCard<Content: View>: View {
    // MARK: - Environment
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Properties
    
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.leading, 5)

            VStack {
                content
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                radius: 8, x: 0, y: 4
            )
        }
        .padding(.horizontal)
    }
}
