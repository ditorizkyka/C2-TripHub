//
//  CircleButton.swift
//  TripHub
//

import SwiftUI

// MARK: - CircleButton

struct CircleButton: View {
    // MARK: - Properties
    
    var icon: String
    
    // MARK: - Body
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.primary)
            .frame(width: 44, height: 44)
            .background(Color(.systemBackground))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
