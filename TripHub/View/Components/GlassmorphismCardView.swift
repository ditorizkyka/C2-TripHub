//
//  GlassmorphismCardView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 21/05/26.
//


import SwiftUI

struct GlassmorphismCardView: View {
//    private var trip : TripModel
    let trip : TripModel
    
    var body: some View {
        NavigationLink(destination: TripView(trip: trip)) {
            ZStack(alignment: .bottom) {
                // 1. GAMBAR LATAR BELAKANG
                // Ganti "bali_placeholder" dengan nama gambar Anda di Assets
                Group {
                    if let data = trip.coverImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                    } else {
                        // Fallback placeholder when data is missing or invalid
                        Color.gray.opacity(0.2)
                    }
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: 360, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                // 2. TOMBOL HATI (GLASS) DI KANAN ATAS
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            print("Favorite ditekan")
                        }) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color(hex: "#4AB855"))
                                .frame(width: 44, height: 44)
                                .background(.thinMaterial) // Efek kaca
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                )
                        }
                        .padding(16)
                    }
                    Spacer() // Mendorong tombol ke atas
                }
                
                // 3. KOTAK INFORMASI BAWAH (GLASS)
                HStack(alignment: .bottom) {
                    // Sisi Kiri (Teks)
                    VStack(alignment: .leading, spacing: 6) {
                        
                        
                        Text(trip.name)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("\(trip.startDate) - \(trip.endDate)")
                            .font(.footnote)
                            .foregroundColor(.black.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Sisi Kanan (Rating & Harga)
                    VStack(alignment: .trailing, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "document.on.document.fill",)
                                .foregroundStyle(Color(hex: "#4AB855"))
                            Text("\(trip.totalDocumentCount) documents")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        
                        // Format Harga
                        Text("\(trip.destinations.count)")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        + Text(" Destination")
                            .font(.footnote)
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
                .padding(16)
                // MEMBUAT EFEK KACA (GLASSMORPHISM)
                .background(.regularMaterial) // Material blur bawaan Apple
                .clipShape(RoundedRectangle(cornerRadius: 20))
                // Garis tepi tipis warna putih untuk mempertegas efek kaca
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .padding(5) // Memberi jarak antara kotak kaca dengan tepi gambar
            }
            
            .frame(width: 360, height: 240)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
        // Bayangan luar card
    }
}

// Preview untuk melihat hasilnya langsung di Xcode
#Preview {
    ZStack {
        // Latar belakang keseluruhan agar card lebih menonjol
        Color.gray.opacity(0.2).ignoresSafeArea()
//        GlassmorphismCardView()
    }
}
