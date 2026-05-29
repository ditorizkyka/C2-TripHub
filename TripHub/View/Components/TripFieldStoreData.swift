//
//  TripFieldStoreData.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 29/05/26.
//

import SwiftUI
import SwiftData
import PhotosUI

struct TripFieldStoreData: View {
    @Bindable var vm: QuickStoreViewModel
    
    // Ambil semua trip dari database SwiftData
    @Query var allTrips: [TripModel]

    // Toggle untuk menampilkan PDF picker
    @State private var showPDFPicker = false

    // Untuk menutup halaman ini (sheet)
    @Environment(\.dismiss) private var dismiss

    // Untuk tahu apakah mode gelap atau terang
    @Environment(\.colorScheme) private var colorScheme

    // ModelContext dari SwiftData (untuk menyimpan data ke database)
    @Environment(\.modelContext) private var modelContext
    // PhotosPicker binding khusus untuk foto sampul trip
    @State private var coverImagePickerItem: PhotosPickerItem? = nil

    // ============================================================
    // MARK: - Computed Properties
    // ============================================================

    // Destinasi yang sudah tersimpan di trip yang dipilih user
    private var existingDestinations: [DestinationModel] {
        if let trip = vm.selectedTrip {
            return trip.destinations
        }
        return []
    }

    // Dokumen yang sudah tersimpan di lokasi yang dipilih
    private var existingDocuments: [DocumentModel] {
        // Jika ada destinasi yang dipilih, tampilkan dokumen destinasi itu
        if let destId = vm.selectedDestinationId {
            // Cek di destinasi existing
            for dest in existingDestinations {
                if dest.id == destId {
                    return dest.documents
                }
            }
            // Cek di destinasi baru
            for dest in vm.newDestinations {
                if dest.id == destId {
                    return dest.documents
                }
            }
        }
        // Jika tidak ada destinasi dipilih, tampilkan dokumen umum trip
        if let trip = vm.selectedTrip {
            return trip.generalDocuments
        }
        return []
    }
    
    // Daftar saran trip
    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("Pilih dari trip yang ada:")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(filteredTrips) { trip in
                Button {
                    vm.selectedTrip = trip
                    vm.searchText = trip.name
                    vm.startDate = trip.startDate

                    let days = Calendar.current.dateComponents(
                        [.day], from: trip.startDate, to: trip.endDate
                    ).day ?? 0

                    if days > 0 {
                        vm.isRangeEnabled = true
                        vm.durationDays = days
                    }
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .foregroundColor(.secondary)
                        Text(trip.name)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Pilih")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
                Divider()
            }
        }
    }

    // Trip yang cocok dengan teks pencarian
    private var filteredTrips: [TripModel] {
        if vm.searchText.isEmpty { return [] }
        let searchLower = vm.searchText.lowercased()
        return allTrips.filter { trip in
            trip.name.lowercased().contains(searchLower)
        }
    }
    
    var body: some View {
        FormCard(title: "Trip Information")  {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select an existing trip or type a new name")
                    .font(.body)
                    .foregroundColor(.secondary)

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Find or create a Trip...", text: $vm.searchText)
                        .autocorrectionDisabled(true)
                        .onChange(of: vm.searchText) { _, _ in
                            vm.selectedTrip = nil
                        }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

                // Konfirmasi trip yang dipilih
                if let trip = vm.selectedTrip {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Trip dipilih: \(trip.name)")
                            .font(.caption)
                    }
                }

                // Saran dari database
                if vm.selectedTrip == nil && !filteredTrips.isEmpty {
                    suggestionList
                }

                // Info akan buat trip baru
                if vm.selectedTrip == nil
                    && !vm.searchText.trimmingCharacters(in: .whitespaces).isEmpty
                    && filteredTrips.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Akan membuat trip baru: \"\(vm.searchText)\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // ── Optional fields (only shown when creating a new trip) ────
                // Cover image and description are only relevant for new trips.
                // When editing an existing trip, use EditTripView instead.
                if vm.selectedTrip == nil && !vm.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Divider()

                    // Cover Image picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cover Image (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        PhotosPicker(selection: $coverImagePickerItem, matching: .images) {
                            // Show a preview if image already selected, else show placeholder
                            if let data = vm.coverImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green, lineWidth: 2)
                                    )
                            } else {
                                HStack(spacing: 10) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.title2)
                                    Text("Pilih foto sampul")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                                .foregroundColor(.green)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5]))
                                )
                            }
                        }
                        // Load the raw Data when user picks an image
                        .onChange(of: coverImagePickerItem) { _, newItem in
                            guard let newItem else {
                                vm.coverImageData = nil
                                return
                            }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    vm.coverImageData = data
                                }
                            }
                        }
                    }

                    // Description TextEditor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        ZStack(alignment: .topLeading) {
                            // Placeholder text
                            if vm.tripDescription.isEmpty {
                                Text("Ceritakan sedikit tentang trip ini...")
                                    .foregroundColor(Color(.placeholderText))
                                    .font(.body)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                            }
                            TextEditor(text: $vm.tripDescription)
                                .frame(minHeight: 90)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
}

#Preview {
    TripFieldStoreData(vm: QuickStoreViewModel())
}
