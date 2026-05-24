//
//  MainTabView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 11/05/26.
//

import SwiftUI

//struct MainTabView: View {
//    @State private var currentTab: TabItemCustom = .home
//    
//    init() {
//        // Menyembunyikan TabBar bawaan
//        UITabBar.appearance().isHidden = true
//    }
//    
//    var body: some View {
//        // Tambahkan alignment .bottom di sini
//        ZStack(alignment: .bottom) {
//            
//            Group {
//                switch currentTab {
//                case .home:
//                    HomeView()
//                case .explore:
//                    ExploreTripView()
//                case .documents:
//                    ExploreDocumentsView()
//                case .add:
//                    AddDocumentsView()
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            // Tambahkan padding bawah pada View konten agar tidak tertutup TabBar
//            .padding(.bottom, 85)
//            
//            // Tab bar akan otomatis menempel di bawah karena alignment ZStack
//            CustomTabBar(selectedTab: $currentTab)
//                .padding(.bottom, 10) // Jarak aman dari edge bawah layar
//        }
//        .ignoresSafeArea(.keyboard, edges: .bottom) // Opsional: agar tidak naik saat keyboard muncul
//    }
//}

struct MainTabView : View {
    var body : some View {
        TabView {
            Tab("Home", systemImage: "house") {
                    HomeView()
                }
            
            Tab("Trip", systemImage: "airplane.up.right") {
                    ExploreTripView()
                }
            
            Tab("Documents", systemImage: "document.on.document") {
                    ExploreDocumentsView()
                }
//                .badge(2)
        }
        
        .tint(Color(hex: "#4AB855"))
    }
}

#Preview {
    MainTabView()
}
