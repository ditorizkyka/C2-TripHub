//
//  ChipItemView.swift
//  TripHub
//

import SwiftUI

// MARK: - ChipItemView

struct ChipItemView: View {
    // MARK: - Properties
    
    var title: String
    var isSelected: Bool
    
    // MARK: - Body
    
    var body: some View {
        Text(title)
            .font(.helveticaCustom(size: 16, weight: .regular))
            .fontWeight(isSelected ? .bold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? Color("primaryGreen") : .primary.opacity(0.7))
            .background(isSelected ? Color("secondaryGreen") : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.4), lineWidth: isSelected ? 0 : 1)
            )
    }
}
