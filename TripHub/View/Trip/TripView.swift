//
//  TripView.swift
//  TripHub
//

import SwiftUI
import SwiftData

// MARK: - TripView

struct TripView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties
    
    let trip: TripModel
    @State private var vm = TripViewModel()
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    Group {
                        if let data = trip.coverImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image("trip_\(trip.imageSeed + 1)")
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width, height: 380)
                    .clipped()

                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(trip.name)
                                    .font(.helveticaCustom(size: 24))
                                    .fontWeight(.medium)
                                
                                HStack(spacing:10) {
                                    Image(systemName: "clock")
                                        .foregroundStyle(.gray)
                                        .font(.system(size: 15))
                                    Text(vm.tripDurationText(for: trip))
                                        .font(.helveticaCustom(size: 15))
                                        .foregroundStyle(.gray)
                                }
                            }
                            Spacer()
                            
                            Button(action: {
                                trip.isPinned.toggle()
                            }) {
                                Image(systemName: trip.isPinned ? "star.fill" : "star")
                                    .font(.system(size: 20))
                                    .foregroundColor(trip.isPinned ? .primaryGreen : .gray)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        
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
                        
                        if let description = trip.tripDescription, !description.isEmpty {
                            Text(description)
                                .font(.helveticaCustom(size: 15))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        } else {
                            Text("No description provided for this trip.")
                                .font(.helveticaCustom(size: 15))
                                .foregroundColor(.gray)
                                .italic()
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Documents")
                                .font(.helveticaCustom(size: 20))
                            
                            if trip.generalDocuments.isEmpty {
                                Text("No documents attached yet.")
                                    .font(.helveticaCustom(size: 14))
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.primaryGray)
                                    .cornerRadius(16)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(trip.generalDocuments) { doc in
                                            DocumentCardView(document: doc) {
                                                vm.selectedDocument = doc
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
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Destination")
                                .font(.helveticaCustom(size: 20))
                            
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
                                    DestinationDropdownView(destination: dest, selectedDocument: $vm.selectedDocument)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(24)
                    .background(Color.backgroundGray)
                    .clipShape(.rect(topLeadingRadius: 40, topTrailingRadius: 40))
                    .offset(y: -40)
                    .padding(.bottom, -40)
                }
            }
            .ignoresSafeArea(edges: .top)
            .sheet(item: $vm.selectedDocument) { doc in
                DocumentPreviewView(document: doc)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {
                        vm.showEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        vm.showDeleteConfirmation = true
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
        .sheet(isPresented: $vm.showEditSheet) {
            EditTripView(trip: trip)
        }
        .confirmationDialog(
            "Delete Trip?",
            isPresented: $vm.showDeleteConfirmation,
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

// MARK: - Previews

#Preview {
    let dummyTrip = TripModel(
        name: "Mountain Climbing",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 3),
        isPinned: false
    )
    return TripView(trip: dummyTrip)
}
