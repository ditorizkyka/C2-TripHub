//
//  StatItem.swift
//  TripHub
//

import SwiftUI

// MARK: - StatItem

struct StatItem: View {
    // MARK: - Properties
    
    var title: String
    var value: String
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.helveticaCustom(size: 13))
                .foregroundColor(.gray)
            Text(value)
                .font(.helveticaCustom(size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}
