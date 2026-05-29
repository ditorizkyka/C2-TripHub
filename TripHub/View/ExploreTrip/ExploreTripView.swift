//
//  ExploreTripView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 12/05/26.
//

import SwiftUI
import SwiftData

struct ExploreTripView: View {
    @State private var search: String = ""
    let categories = ["All","Starred", "Upcoming", "Ongoing", "Past"]
    @State private var selectedCategory = "All"
    
    @Query var allTrips: [TripModel]
    
    var filteredTrips: [TripModel] {
        let today = Date()
        
        // Langkah 1: Filter berdasarkan kategori Chip
        let categoryFiltered: [TripModel]
        
        switch selectedCategory {
        case "Starred":
            categoryFiltered = allTrips.filter { $0.isPinned } // Asumsi Anda menggunakan isPinned untuk Starred
        case "Upcoming":
            categoryFiltered = allTrips.filter { $0.isUpcoming(at: today) }
        case "Ongoing":
            categoryFiltered = allTrips.filter { $0.isOngoing(at: today) }
        case "Past":
            categoryFiltered = allTrips.filter { $0.isPast(at: today) }
        default: // Kasus untuk "All"
            categoryFiltered = allTrips
        }
        
        // Langkah 2: Filter berdasarkan teks pencarian (Search Bar)
        if search.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { trip in
                // Mengecek apakah nama trip mengandung teks yang diketik (mengabaikan huruf besar/kecil)
                trip.name.localizedCaseInsensitiveContains(search)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    // 4. HStack untuk menjejerkan chip ke samping
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.self) { category in
//                                         Memanggil desain chip di bawah
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
                
                ForEach(filteredTrips) { trip in
                    // 'trip' di sini sudah berupa TripModel utuh
                    
                    GlassmorphismCardView(trip: trip)
                        .padding(.vertical, 8)
                }
                
//                // 👇 Tambahkan ini agar ketahuan kalau datanya memang kosong
//                if filteredTrips.isEmpty {
//                    VStack(spacing: 12) {
//                        
//                        Image(systemName: "tray")
//                            .font(.system(size: 40))
//                            .foregroundColor(.gray)
//                        Text("No trips found")
//                            .font(.helveticaCustom(size: 16))
//                            .foregroundColor(.gray)
//                    }
//
//                    .padding(.top, 50)
//                }
                
            }
            // 👇 Tambahkan overlay di sini (menempel pada ScrollView)
            .overlay {
                if filteredTrips.isEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "map")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.gray)
                        
                        VStack(spacing: 10) {
                            Text("No trips found")
                                .font(.helveticaCustom(size: 22, weight: .medium))
                                .foregroundStyle(.gray)
                            
                            Text("You don't have any trips\nthat match this filter.")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    // Frame ini memastikan dia mengambil seluruh ruang layar dan berada di tengah
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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



struct ChipItemView: View {
    var title: String
    var isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.helveticaCustom(size: 16, weight: .regular))
            .fontWeight(isSelected ? .bold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // 1. Warna Teks (Foreground)
            // Menggunakan "primaryGreen" saat dipilih, dan abu-abu standar saat tidak dipilih
            .foregroundColor(isSelected ? Color("primaryGreen") : .primary.opacity(0.7))
            
            // 2. Warna Latar (Background)
            // Menggunakan "secondaryGreen". Karena sudah di-set di Assets,
            // SwiftUI otomatis pakai warna terang di Light Mode dan gelap di Dark Mode
            .background(isSelected ? Color("secondaryGreen") : Color.clear)
            
            .clipShape(Capsule())
            
            // 3. Garis Tepi (Border)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.4), lineWidth: isSelected ? 0 : 1)
            )
    }
}

#Preview {
    ExploreTripView()
}
