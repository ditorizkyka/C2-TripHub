//
//  TripView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 26/05/26.
//

import SwiftUI


struct TripView: View {
    let trip: TripModel
    
    var body: some View {
        // 1. ZStack Paling Luar (Agar tombol Start Journey bisa mengambang di bawah)
        ZStack(alignment: .bottom) {
            
            ScrollView {
                VStack(spacing: 0) {
                    // ==========================================
                    // BAGIAN 1: HEADER GAMBAR & KUSTOM NAV BAR
                    // ==========================================
                    Image("bali_placeholder") // Ganti dengan gambar Anda
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: 380)
                        .clipped() // Memastikan gambar tidak meluber
                        // Menggunakan overlay untuk membuat tombol back & menu melayang di atas gambar
                        
                    
                    // ==========================================
                    // BAGIAN 2: KONTEN PUTIH YANG MENIMPA GAMBAR
                    // ==========================================
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header Judul & Tombol Hati
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(trip.name)
                                    .font(.system(size: 28, weight: .bold))
                                
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.gray)
                                    Text("San Francisco") // Bisa diganti trip.location jika ada
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            
                            // Tombol Love
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primaryGreen)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Kotak Stats (Jarak, Cuaca, Sunset)
                        HStack {
                            StatItem(title: "Documents", value: "18 Doc")
                            Divider().frame(height: 40)
                            StatItem(title: "Duration", value: "8 Days")
                            Divider().frame(height: 40)
                            StatItem(title: "Destination", value: "7 Dest")
                        }
                        .padding(.vertical, 16)
                        .background(Color.primaryGray)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                        
                        // Deskripsi
                        Text("An adventure is an exciting experience that is typically bold, sometimes readmore Keep hiking anywhere without any hassle.")
                            .font(.system(size: 16))
                            .foregroundColor(.black.opacity(0.8))
                            .lineSpacing(4)
                        
                        // Galeri (Placeholder)
                        HStack {
                            Text("Your Destination")
                                .font(.title3)
                                .fontWeight(.bold)
//                            Spacer()
//                            Text("See all >")
//                                .foregroundColor(.blue)
                        }
                        
                        VStack {
                            ForEach(trip.destinations) { dest in
                                DestinationDropdownView(destination: dest)
                            }
                        }
                        
                        // Ruang kosong di bawah agar konten tidak tertutup tombol "Start Journey"
                        Spacer().frame(height: 120)
                    }
                    .padding(24)
                    .background(Color.backgroundGray) // Warna background dasar (agak kebiruan/abu terang)
                    // 👇 INI KUNCINYA: Memotong ujung atasnya saja
                    .clipShape(.rect(topLeadingRadius: 40, topTrailingRadius: 40))
                    // 👇 INI KUNCINYA: Menarik view ini ke atas sejauh 40px agar menimpa gambar
                    .offset(y: -40)
                    // Mengembalikan ukuran layout bawah yang terpotong karena offset
                    .padding(.bottom, -40)
                }
                
            }
            .ignoresSafeArea(edges: .top)
            // Wajib di ScrollView agar gambar mentok ke atas
            
            // ==========================================
            // BAGIAN 3: FLOATING BUTTON (START JOURNEY)
            // ==========================================
            Button(action: {
                // Aksi Start Journey
            }) {
                Text("Start Journey")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(30)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 10)
            // Jarak dari bawah layar
        }
        // 👇 TAMBAHKAN TOOLBAR DI SINI (Di luar ZStack)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            // Aksi saat tombol Edit ditekan
                            // Misalnya: memunculkan sheet untuk edit trip
                            print("Tombol Edit Ditekan!")
                        }) {
                            // Anda bisa memakai Teks atau Ikon
                            Text("Edit")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue) // Sesuaikan warnanya agar kontras dengan gambar Anda
                            
                            // Atau jika ingin menggunakan ikon pensil:
                            // Image(systemName: "pencil.circle.fill")
                            //    .font(.title2)
                            //    .symbolRenderingMode(.multicolor)
                        }
                    }
                }
                // Opsional: Agar background navigation bar transparan menyatu dengan gambar
                .toolbarBackground(.hidden, for: .navigationBar)
        
    }
}

struct DestinationDropdownView: View {
    // Data destinasi dan dokumennya dari SwiftData
    @Bindable var destination: DestinationModel
    
    // State untuk kontrol buka/tutup dropdown
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack {
            DisclosureGroup(isExpanded: $isExpanded) {
                // Konten saat dropdown terbuka
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Destination Documents :")
                        .font(.helveticaCustom(size: 16))
                        .foregroundColor(.gray)
                    
                    // 👇 Horizontal ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            // Looping data asli dari destinasi Anda
                            ForEach(destination.documents) { doc in
                                
                                // 👇 Memanggil DocumentCardView buatan Anda
                                DocumentCardView(document: doc) {
                                    // Aksi saat dokumen di-tap
                                    print("Dokumen \(doc.name) ditekan!")
                                    // Anda bisa memanggil navigasi ke PDF Viewer di sini
                                }
                                // Batasi lebarnya agar rapi berjejer ke samping
                                .frame(width: 100)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.trailing, 20)
                    }
                    
                    // Tampilan jika tidak ada dokumen
                    if destination.documents.isEmpty {
                        Text("No documents attached.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            } label: {
                // Tampilan judul dropdown
                Text("📍 Destination : \(destination.name)")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color("primaryGray")) // Sesuaikan nama warna Anda
            .cornerRadius(12)
        }
    }
}



// MARK: - Komponen Bantuan agar kode rapi

// Komponen Tombol Bulat di Header
struct CircleButton: View {
    var icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.black)
            .frame(width: 44, height: 44)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Komponen Teks Statistik
struct StatItem: View {
    var title: String
    var value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let dummyTrip = TripModel(
        name: "Mountain Climbing",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 3),
        isPinned: false
    )
    return TripView(trip: dummyTrip)
}

#Preview {
    
    // 3. Buat data dummy Anda
    let dummyTrip = TripModel(
        name: "Liburan ke Tavarua",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 3),
        isPinned: false
    )
    
    return TripView(trip: dummyTrip)
}
