//
//  TripView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 26/05/26.
//

import SwiftUI
import SwiftData

struct TripView: View {
    let trip: TripModel
    @State private var selectedDocument: DocumentModel? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // State untuk membuka halaman edit trip
    @State private var showEditSheet = false
    // State untuk konfirmasi hapus trip
    @State private var showDeleteConfirmation = false

    var body: some View {
        // 1. ZStack Paling Luar (Agar tombol Start Journey bisa mengambang di bawah)
        ZStack(alignment: .bottom) {

            ScrollView {
                VStack(spacing: 0) {
                    // ==========================================
                    // BAGIAN 1: HEADER GAMBAR
                    // Tampilkan foto sampul user jika ada, atau fallback ke placeholder
                    // ==========================================
                    Group {
                        if let data = trip.coverImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image("bali_placeholder")
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width, height: 380)
                    .clipped()

                    // ==========================================
                    // BAGIAN 2: KONTEN PUTIH YANG MENIMPA GAMBAR
                    // ==========================================
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header Judul & Tombol Hati
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(trip.name)
                                    .font(.helveticaCustom(size: 24))
                                    .fontWeight(.medium)
                                
                                HStack {
                                    Image(systemName: "record.circle")
                                        .foregroundColor(.red)
                                    
                                    Text("On Going Trip") // Bisa diganti trip.location jika ada
                                        .foregroundColor(.gray).font(.helveticaCustom(size: 17))
                                    
                                }
                            }
                            Spacer()
                            
                            // Tombol Love
                            Button(action: {
                                trip.isPinned.toggle()
                            }) {
                                Image(systemName: trip.isPinned ? "star.fill" : "star")
                                    .font(.system(size: 20))
                                    .foregroundColor(trip.isPinned ? .primaryGreen : .gray)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        
                        // Kotak Stats (Jarak, Cuaca, Sunset)
                        HStack {
                            StatItem(title: "Documents", value: "\(trip.totalDocumentCount) Doc")
                            Divider().frame(height: 40)
                            
                            let days = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 1
                            StatItem(title: "Duration", value: "\(max(1, days)) Days")
                            
                            Divider().frame(height: 40)
                            StatItem(title: "Destination", value: "\(trip.destinations.count) Dest")
                        }
                        .padding(.vertical, 16)
                        .background(Color.primaryGray)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 4, y: 4)
                        
                        // Deskripsi
                        if let description = trip.tripDescription, !description.isEmpty {
                            Text(description)
                                .font(.helveticaCustom(size: 15))
                                .foregroundColor(.black.opacity(0.8))
                                .lineSpacing(4)
                        } else {
                            Text("No description provided for this trip.")
                                .font(.helveticaCustom(size: 15))
                                .foregroundColor(.gray)
                                .italic()
                        }
                        
                        
                        // ==========================================
                        // SECTION: YOUR DOCUMENTS
                        // ==========================================
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Documents")
                                .font(.helveticaCustom(size: 20))
                            
                            // Pengondisian jika dokumen kosong
                            if trip.generalDocuments.isEmpty {
                                Text("No documents attached yet.")
                                    .font(.helveticaCustom(size: 14))
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.primaryGray)
                                    .cornerRadius(16)
                            } else {
                                // Horizontal ScrollView (Tinggi menyesuaikan konten)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        // Looping data asli
                                        ForEach(trip.generalDocuments) { doc in
                                            DocumentCardView(document: doc) {
                                                selectedDocument = doc
                                            }
                                            .frame(width: 100)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                .background(Color.primaryGray)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                            }
                        }
                        
                        
                        // ==========================================
                        // SECTION: YOUR DESTINATION
                        // ==========================================
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Destination")
                                .font(.helveticaCustom(size: 20))
                            
                            // Pengondisian jika destinasi kosong
                            if trip.destinations.isEmpty {
                                Text("No destinations added yet.")
                                    .font(.helveticaCustom(size: 14))
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.primaryGray)
                                    .cornerRadius(16)
                            } else {
                                ForEach(trip.destinations) { dest in
                                    DestinationDropdownView(destination: dest, selectedDocument: $selectedDocument)
                                }
                            }
                        }
                        
                        // Ruang kosong di bawah agar konten tidak tertutup tombol "Start Journey"
                        Spacer().frame(height: 120)
                    }
                    .padding(24)
                    .background(Color.backgroundGray) // Warna background dasar
                    // INI KUNCINYA: Memotong ujung atasnya saja
                    .clipShape(.rect(topLeadingRadius: 40, topTrailingRadius: 40))
                    // INI KUNCINYA: Menarik view ini ke atas sejauh 40px agar menimpa gambar
                    .offset(y: -40)
                    // Mengembalikan ukuran layout bawah yang terpotong karena offset
                    .padding(.bottom, -40)
                }
                
            }
            .ignoresSafeArea(edges: .top) // Wajib di ScrollView agar gambar mentok ke atas
            // ── Sheet: Preview dokumen ─────────────────────────
            // PENTING: .sheet harus di sini (di luar ScrollView/Grid), bukan di dalam
            .sheet(item: $selectedDocument) { doc in
                DocumentPreviewView(document: doc)
            }
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
            .padding(.bottom, 10) // Jarak dari bawah layar
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    // role: .destructive otomatis membuat warna teks menjadi merah di menu
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        // Sheet untuk halaman edit trip
        .sheet(isPresented: $showEditSheet) {
            EditTripView(trip: trip)
        }
        // Dialog konfirmasi untuk delete trip
        .confirmationDialog(
            "Delete Trip?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(trip)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(trip.name)'? This action cannot be undone and will delete all associated destinations and documents.")
        }
    }
}

// MARK: - Komponen Pendukung

struct DestinationDropdownView: View {
    // Data destinasi dan dokumennya dari SwiftData
    @Bindable var destination: DestinationModel
    @Binding var selectedDocument: DocumentModel?
    
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
                    
                    // Horizontal ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(destination.documents) { doc in
                                DocumentCardView(document: doc) {
                                    selectedDocument = doc
                                }
//                                .frame(width: 100)
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
                    .font(.helveticaCustom(size: 16))
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color.primaryGray) // Sesuaikan nama warna Anda
            .cornerRadius(12)
        }
    }
}

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
                .font(.helveticaCustom(size: 13))
                .foregroundColor(.gray)
            Text(value)
                .font(.helveticaCustom(size: 20))
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let dummyTrip = TripModel(
        name: "Mountain Climbing",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 3),
        isPinned: false
    )
    return TripView(trip: dummyTrip)
}

#Preview("Tavarua Trip") {
    let dummyTrip = TripModel(
        name: "Liburan ke Tavarua",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 3),
        isPinned: false
    )
    return TripView(trip: dummyTrip)
}
