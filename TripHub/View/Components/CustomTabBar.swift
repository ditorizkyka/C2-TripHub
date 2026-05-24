//
//  CustomTabBar.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 14/05/26.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab : TabItemCustom
    
    var body: some View {
        HStack(spacing: 12) { // Jarak antara Bar Hitam dan Tombol Hijau
            
            // --- BAR UTAMA (HITAM) ---
            HStack(spacing: 0) {
                ForEach([TabItemCustom.home, .explore, .documents], id: \.rawValue) { tab in
                    tabButton(tab: tab)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 65)
            .background(Color.black)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            
            // --- TOMBOL TAMBAH (HIJAU) ---
            tabButton(tab: .add)
                .frame(width: 65, height: 65) // Kotak sempurna sejajar tinggi bar
                .background(Color(hex: "#4AB855"))
                .foregroundColor(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    func tabButton(tab: TabItemCustom) -> some View {
        VStack {
            Image(systemName: selectedTab == tab ? "\(tab.rawValue).fill" : tab.rawValue)
                .font(.system(size: 22, weight: .semibold))
                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Mengisi ruang yang tersedia
        .background(selectedTab == tab && tab != .add ? Color.white : Color.clear)
        .foregroundColor(selectedTab == tab && tab != .add ? .black : .white)
        .cornerRadius(15)
        .padding(6) // Memberi jarak antara background putih dan tepi bar
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }
    }
}



#Preview {
    @State var selectedTab: TabItemCustom = .home
    CustomTabBar(selectedTab: $selectedTab )
}

