import Foundation
import SwiftUI
import SwiftData
import PhotosUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TripStore.createdAt, order: .reverse) var documents: [TripStore]
    @State private var showOptions = false
    @State private var selectedPhoto: PhotosPickerItem?
    
    @State private var showQuickStore = false
    
    let deliveryGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.secondaryGreen, // Light Green (kiri atas)
            Color.primaryGreen.opacity(0.6) // Primary Green soft (kanan bawah)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    Color.backgroundGray
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header custom (HStack gambar & profil) SUDAH DIHAPUS
                        
                        VStack(alignment:.leading, spacing: 20) {
                            Text("Ongoing Trip")
                                .font(.helveticaCustom(size: 23))
                            
                            VStack(alignment: .leading, spacing: 15) {
                                // Bagian Atas: Info Tracking & Status
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Tracking number")
                                            .font(.system(size: 14))
                                            .foregroundColor(.black.opacity(0.7))
                                        Text("#36123217")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    
                                    Spacer()
                                    
                                    // Status Badge (In transit)
                                    Text("In transit")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.black)
                                        .cornerRadius(15)
                                }
                                
                                // Bagian Tengah: Progress Bar Custom
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.5))
                                            .frame(height: 6)
                                        
                                        Capsule()
                                            .fill(Color(hex: "#4AB855"))
                                            .frame(width: geo.size.width * 0.6, height: 6) // Progress 60%
                                    }
                                }
                                .frame(height: 6)
                                
                                // Bagian Bawah: Route & Date
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("From").font(.caption).foregroundColor(.black.opacity(0.6))
                                        Text("Paris").font(.system(size: 16, weight: .semibold))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .leading) {
                                        Text("To").font(.caption).foregroundColor(.black.opacity(0.6))
                                        Text("Berlin").font(.system(size: 16, weight: .semibold))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("Arrival date").font(.caption).foregroundColor(.black.opacity(0.6))
                                        Text("21 Dec, 2025").font(.system(size: 14, weight: .semibold))
                                    }
                                }
                            }
                            .padding(20)
                            .background(deliveryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                        }

                        VStack(alignment:.leading, spacing: 20) {
                            Text("Categories")
                                .font(.helveticaCustom(size: 23))
                            
                            HStack(alignment: .center, spacing: 5) {
                                ForEach(DocumentCategory.allCases, id: \.rawValue) { category in
                                    HStack {
                                        VStack(alignment:.leading, spacing: 10) {
                                            Image(systemName: category.rawValue)
                                                .font(.title2)
                                                .fontWeight(.light)
                                                
                                            Text(category.title)
                                                .font(.helveticaCustom(size: 18))
                                        }
                                        .padding(.vertical,13)
                                        .padding(.horizontal,20)
                                        
                                        Spacer()
                                    }
                                    .frame(maxHeight:100)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(20)
                                }
                            }
                        }
                        
                        VStack(alignment : .leading, spacing: 20) {
                            Text("Starred Documents")
                                .font(.helveticaCustom(size: 23))
                                
                            LazyVStack(spacing: 12) {
                                ForEach(0..<3, id: \.self) { _ in
                                    StarredDocumentsCard()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)    // Padding disesuaikan agar rapi dengan NavigationTitle
                    .padding(.bottom, 40)
                }
            }
           
            .navigationTitle("Home")
            .toolbar {
                                ToolbarItemGroup(placement: .topBarTrailing) {
                                    Button(action: {
                                        // Action
                                    }) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.black)
                                            .frame(width: 36, height: 36)
                                            .background(Color.white) // Lingkaran putih
                                            .clipShape(Circle())
                                            // 👇 Shadow yang sama untuk ikon kamera
                                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    }
                                    
                                    Button(action: {
                                        showQuickStore = true
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 36, height: 36)
                                            .background(Color(hex: "#4AB855")) // Warna hijau WA
                                            .clipShape(Circle())
                                            // Tombol plus di WA biasanya tidak pakai shadow,
                                            // tapi kalau mau disamakan bisa di-uncomment di bawah ini:
                                            // .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    }
                                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            
            .sheet(isPresented: $showQuickStore) {
                QuickStoreView()
            }
        }
    }
}

#Preview {
    HomeView()
}
