//
//  StarredDocumentsCard.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 14/05/26.
//

import SwiftUI

struct StarredDocumentsCard: View {
    var orderNumber: String = "#7620937"
    var route: String = "From Paris to Berlin"
    var status: String = "Delivered"
    
    let document : DocumentModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Status Badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Uploaded on \(Text(document.uploadDate.formatted(.dateTime.day().month(.wide).year())))")
                        .lineLimit(1)
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text(document.name)
                        .lineLimit(1)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
                Spacer()
                Text(document.categoryRawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primaryGray) // Abu-abu muda sesuai branding
                    .clipShape(Capsule())
            }
            
            // Detail Order
            
//            .padding(.top, -10) // Menyesuaikan posisi agar sejajar dengan badge
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(Color.gray.opacity(0.8), lineWidth: 1) // Border tipis sesuai gambar
        )
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
//        .padding(.horizontal)
    }
}
