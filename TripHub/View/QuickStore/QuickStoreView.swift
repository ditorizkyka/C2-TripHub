//
//  QuickStoreView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 22/05/26.
//

import SwiftUI

struct QuickStoreView: View {
    @State private var vm = QuickStoreViewModel()
    @Environment(TripStore.self) private var store
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundGray
                    .edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        Text("Upload your trip documents and destinations based on your preferences. Remember to double-check your arrival times for a smoother journey!")
                            .padding(.horizontal)
                            .foregroundStyle(.secondary)
                            .font(.body)
                        
//                        // SECTION 1: TRIP INFO & SEARCH
//                        tripInfoSection
//                        
//                        // SECTION 2: DATE PICKER
//                        datePickerSection
//                        
//                        // SECTION 3: DESTINATION LIST
//                        destinationSection
//                        
//                        // SECTION 4: DOCUMENT UPLOAD
//                        documentUploadSection
//                        
//                        // SAVE BUTTON
//                        saveButton
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Add Documents")
        }
        
    }
    
    struct FormCard<Content: View>: View {
        @Environment(\.colorScheme) private var colorScheme
        let title: String
        let content: Content
        
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.leading, 5)
                
                VStack {
                    content
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.03), lineWidth: 1)
                )
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
        }
    }
    
    private var tripInfoSection: some View {
        FormCard(title: "Trip Information") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select your main trip group")
                    .font(.body).foregroundColor(.secondary)
                
                TextField("Find or create a Trip", text: $vm.searchText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                if !vm.searchText.isEmpty && vm.selectedTrip != vm.searchText {
                    suggestionList
                }
            }
        }
    }
    
    private var suggestionList: some View {
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                // Show existing trips from store
                let existingNames = store.trips.map { $0.name }
                let filtered = existingNames.filter { $0.lowercased().contains(vm.searchText.lowercased()) }
                
                ForEach(filtered, id: \.self) { tripName in
                    Button(action: {
                        // 1. Cari data Trip aslinya dari store berdasarkan nama
                        
                        if let actualTrip = store.trips.first(where: { $0.name == tripName }) {
                            // 2. Update teks pencarian
                            vm.searchText = actualTrip.name
                            vm.selectedTrip = actualTrip.name
                            
                            // 3. Update Start Date agar kalender otomatis berubah
                            vm.startDate = actualTrip.startDate
                            
                            // 4. Kalkulasi selisih hari untuk mengupdate durasi (opsional tapi disarankan)
                            let days = Calendar.current.dateComponents([.day], from: actualTrip.startDate, to: actualTrip.endDate).day ?? 0
                            if days > 0 {
                                vm.isRangeEnabled = true
                                vm.durationDays = days
                            } else {
                                vm.isRangeEnabled = false
                                vm.durationDays = 1
                            }
                        } else {
                            // Fallback jika tidak ketemu (seharusnya selalu ketemu)
                            vm.searchText = tripName
                            vm.selectedTrip = tripName
                        }
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.2.circlepath")
                            Text(tripName).font(.custom("Helvetica", size: 15))
                            Spacer()
                            Text("Update Existing").font(.caption2).foregroundColor(.blue)
                            Image(systemName: "arrow.up.left").font(.caption2)
                        }
                        .foregroundColor(.primary).padding(.vertical, 5)
                    }
                }
                
                if filtered.isEmpty {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Will create new trip: \"\(vm.searchText)\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
        }

}

#Preview {
    QuickStoreView()
}
