//
//  ExploreTripView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 12/05/26.
//

import SwiftUI

struct ExploreTripView: View {
    @State private var search: String = ""
    let categories = ["Semua", "Pantai", "Gunung", "Budaya", "Kuliner", "Hutan", "Kota"]
    @State private var selectedCategory = "Semua"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    // 4. HStack untuk menjejerkan chip ke samping
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.self) { category in
                                        // Memanggil desain chip di bawah
                                        ChipItemView(
                                            title: category,
                                            isSelected: selectedCategory == category
                                        )
                                        .onTapGesture {
                                            // Mengubah status terpilih ketika diklik
                                            withAnimation(.spring()) {
                                                selectedCategory = category
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16) // Jarak awal dan akhir konten dengan layar
                                .padding(.vertical, 8)
                }
                ForEach(0..<3,) { index in
                            // Memanggil View Card yang sudah dibuat sebelumnya
                            GlassmorphismCardView()
                        .padding(.vertical,8)
                        }
                
            }
            .navigationTitle("Your Trip")
            .searchable(text: $search, placement: .navigationBarDrawer)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        // Action
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "#4AB855"))
                            .clipShape(Circle())
                           
                    }
                }
            }
        }
    }
}

struct ChipItemView : View {
    var title : String
    var isSelected : Bool
    
    var body : some View {
        Text(title)
            .font(.helveticaCustom(size: 16, weight: .regular))
//            .fontWeight(.medium)
            .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        // Warna berubah berdasarkan status terpilih
                        .foregroundColor(isSelected ? .white : .black.opacity(0.7))
                        .background(isSelected ? Color.black : Color.gray.opacity(0.0))
                        // 5. Membuat bentuk lonjong (Kapsul)
                        .clipShape(Capsule())
                        // 6. Opsional: Garis tepi tipis untuk chip yang tidak terpilih
                        .overlay(
                            Capsule()
                                .stroke(Color.gray.opacity(0.4), lineWidth: isSelected ? 0 : 1)
                        )
    }
}

#Preview {
    ExploreTripView()
}
