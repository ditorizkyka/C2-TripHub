//
//  DestinationFieldStoreData.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 29/05/26.
//

import SwiftUI
import SwiftData


struct DestinationFieldStoreData: View {
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
    

    
    var body: some View {
        FormCard(title: "Destinasi (Opsional)") {
            VStack(spacing: 15) {

                Text("Tambah destinasi jika ingin menyimpan dokumen per kota/tempat")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Input nama destinasi
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.green)
                    TextField("Nama Kota atau Tempat", text: $vm.destinationName)
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

                // Tanggal destinasi
                DatePicker("Waktu Tiba", selection: $vm.destinationStartDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                DatePicker("Waktu Pergi", selection: $vm.destinationEndDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Tombol tambah
                Button {
                    addDestination()
                } label: {
                    Label("Tambah Destinasi", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(vm.destinationName.isEmpty ? Color(.systemGray4) : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(vm.destinationName.isEmpty)

                // Destinasi baru (belum disimpan)
                if !vm.newDestinations.isEmpty {
                    Divider()
                    Text("Destinasi Baru")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(vm.newDestinations) { dest in
                        makeDestinationRow(dest: dest)
                    }
                }

                // Destinasi yang sudah ada di trip yang dipilih
                if !existingDestinations.isEmpty {
                    Divider()
                    Text("Sudah tersimpan di \"\(vm.selectedTrip?.name ?? "")\"")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(existingDestinations) { dest in
                        makeDestinationRow(dest: dest)
                    }
                }
            }
        }
    }
    // Destinasi yang sudah tersimpan di trip yang dipilih user
    private var existingDestinations: [DestinationModel] {
        if let trip = vm.selectedTrip {
            return trip.destinations
        }
        return []
    }
    
    private func addDestination() {
        let name = vm.destinationName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return }

        let newDest = DestinationModel(
            name: name,
            startDate: vm.destinationStartDate,
            startTime: vm.destinationStartDate,
            endDate: vm.destinationEndDate,
            endTime: vm.destinationEndDate
        )
        vm.newDestinations.append(newDest)
        vm.destinationName = ""
    }
    // Satu baris destinasi (bisa dipilih)
    private func makeDestinationRow(dest: DestinationModel) -> some View {
        let isSelected = vm.selectedDestinationId == dest.id

        return Button {
            if isSelected {
                vm.selectedDestinationId = nil
            } else {
                vm.selectedDestinationId = dest.id
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dest.name)
                        .foregroundColor(.primary)
                    Text(dest.startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding(10)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.tertiarySystemFill))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DestinationFieldStoreData(vm: QuickStoreViewModel())
}
