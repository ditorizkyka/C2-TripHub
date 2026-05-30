import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

// MARK: - QuickStoreView

struct QuickStoreView: View {
    // MARK: - Environment
    
    @Query var allTrips: [TripModel]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties
    
    @State private var vm = QuickStoreViewModel()
    @State private var showPDFPicker = false
    @State private var coverImagePickerItem: PhotosPickerItem? = nil

    private var existingDestinations: [DestinationModel] {
        if let trip = vm.selectedTrip {
            return trip.destinations
        }
        return []
    }

    private var existingDocuments: [DocumentModel] {
        if let destId = vm.selectedDestinationId {
            for dest in existingDestinations {
                if dest.id == destId {
                    return dest.documents
                }
            }
            for dest in vm.newDestinations {
                if dest.id == destId {
                    return dest.documents
                }
            }
        }
        if let trip = vm.selectedTrip {
            return trip.generalDocuments
        }
        return []
    }

    private var filteredTrips: [TripModel] {
        if vm.searchText.isEmpty { return [] }
        let searchLower = vm.searchText.lowercased()
        return allTrips.filter { trip in
            trip.name.lowercased().contains(searchLower)
        }
    }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        Text("Upload your trip documents and destinations based on your preferences.")
                            .padding(.horizontal)
                            .foregroundStyle(.secondary)

                        tripInfoSection
                        datePickerSection
                        destinationSection
                        documentUploadSection
                        saveButton
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Add Documents")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(
                isPresented: $showPDFPicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: true
            ) { result in
                handlePDFImport(result: result)
            }
        }
    }

    // MARK: - Sub-views

    private var tripInfoSection: some View {
        FormCard(title: "Trip Information") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select an existing trip or type a new name")
                    .font(.body)
                    .foregroundColor(.secondary)

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

                if let trip = vm.selectedTrip {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Selected Trip: \(trip.name)")
                            .font(.caption)
                    }
                }

                if vm.selectedTrip == nil && !filteredTrips.isEmpty {
                    suggestionList
                }

                if vm.selectedTrip == nil
                    && !vm.searchText.trimmingCharacters(in: .whitespaces).isEmpty
                    && filteredTrips.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Creating new trip: \"\(vm.searchText)\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if vm.selectedTrip == nil && !vm.searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cover Image (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        PhotosPicker(selection: $coverImagePickerItem, matching: .images) {
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
                                    Text("Select cover photo")
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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        ZStack(alignment: .topLeading) {
                            if vm.tripDescription.isEmpty {
                                Text("Tell us a bit about this trip...")
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

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("Select from existing trips:")
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
                        Text("Select")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
                Divider()
            }
        }
    }

    private var datePickerSection: some View {
        FormCard(title: "Trip Date") {
            VStack(alignment: .leading,spacing: 15) {
                DatePicker("Start Date", selection: $vm.startDate, displayedComponents: .date)
                Divider()
                Toggle("Add Duration", isOn: $vm.isRangeEnabled.animation())
                if vm.isRangeEnabled {
                    Divider()
                    Stepper("\(vm.durationDays) Days", value: $vm.durationDays, in: 1...30)
                        .fontWeight(.semibold)
                    Text("Back on: \(vm.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var destinationSection: some View {
        FormCard(title: "Destinations (Optional)") {
            VStack(spacing: 15) {
                Text("Add destinations to organize documents by city/place")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.green)
                    TextField("City or Place Name", text: $vm.destinationName)
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

                DatePicker("Arrival Time", selection: $vm.destinationStartDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                DatePicker("Departure Time", selection: $vm.destinationEndDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button {
                    addDestination()
                } label: {
                    Label("Add Destination", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(vm.destinationName.isEmpty ? Color(.systemGray4) : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(vm.destinationName.isEmpty)

                if !vm.newDestinations.isEmpty {
                    Divider()
                    Text("New Destinations")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(vm.newDestinations) { dest in
                        makeDestinationRow(dest: dest)
                    }
                }

                if !existingDestinations.isEmpty {
                    Divider()
                    Text("Saved in \"\(vm.selectedTrip?.name ?? "")\"")
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

    private var documentUploadSection: some View {
        FormCard(title: "Documents") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Upload tickets, identity, or other travel documents")
                    .font(.body)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    PhotosPicker(selection: $vm.selectedItems, matching: .images) {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus").font(.title2)
                            Text("Image").font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }

                    Button {
                        showPDFPicker = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "doc.badge.plus").font(.title2)
                            Text("PDF").font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }
                }

                if !existingDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saved Documents")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        ForEach(existingDocuments) { doc in
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(doc.isImage ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: doc.isImage ? "photo" : "doc.fill")
                                        .foregroundColor(doc.isImage ? .blue : .orange)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.name).font(.caption)
                                    Text(doc.getCategory().title).font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                    .padding(.top, 8)
                }

                if !vm.pendingDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(vm.totalFileCount) files ready to upload")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)

                        ForEach($vm.pendingDocuments) { $doc in
                            SwipeablePendingDocRow(
                                document: $doc,
                                onDelete: {
                                    withAnimation {
                                        vm.pendingDocuments.removeAll { $0.id == doc.id }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            vm.saveTrip(modelContext: modelContext)
            dismiss()
        } label: {
            HStack {
                if vm.isSaving {
                    ProgressView().tint(.white)
                    Text("Saving...")
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save All")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(vm.canSave ? Color.green : Color(.systemGray4))
            .cornerRadius(14)
            .padding(.horizontal)
        }
        .disabled(!vm.canSave || vm.isSaving)
    }

    // MARK: - Helper Methods

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

    private func handlePDFImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                let didStart = url.startAccessingSecurityScopedResource()
                let pdfData = try? Data(contentsOf: url)
                if didStart {
                    url.stopAccessingSecurityScopedResource()
                }

                if let data = pdfData {
                    let fileName = url.deletingPathExtension().lastPathComponent
                    let newDoc = PendingDocument(
                        isImage: false,
                        imageData: nil,
                        pdfData: data,
                        name: fileName
                    )
                    vm.pendingDocuments.append(newDoc)
                }
            }
        case .failure(let error):
            print("Failed to import PDF: \(error.localizedDescription)")
        }
    }
}

// MARK: - Previews

#Preview {
    QuickStoreView()
        .modelContainer(
            for: [TripModel.self, DestinationModel.self, DocumentModel.self],
            inMemory: true
        )
}
