import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

// ============================================================
// MARK: - QuickStoreView
// ============================================================
// Halaman form untuk upload dokumen ke sebuah trip.
//
// Alur penggunaan:
// 1. Pilih trip yang sudah ada ATAU ketik nama trip baru
// 2. Atur tanggal perjalanan
// 3. (Opsional) Tambah destinasi
// 4. Upload gambar atau PDF
// 5. Tekan "Simpan"

struct QuickStoreView: View {

    // Ambil semua trip dari database SwiftData
    @Query var allTrips: [TripModel]

    // ViewModel yang menyimpan semua state form ini
    @State private var vm = QuickStoreViewModel()

    // Toggle untuk menampilkan PDF picker
    @State private var showPDFPicker = false

    // PhotosPicker binding khusus untuk foto sampul trip
    @State private var coverImagePickerItem: PhotosPickerItem? = nil

    // Untuk menutup halaman ini (sheet)
    @Environment(\.dismiss) private var dismiss

    // Untuk tahu apakah mode gelap atau terang
    @Environment(\.colorScheme) private var colorScheme

    // ModelContext dari SwiftData (untuk menyimpan data ke database)
    @Environment(\.modelContext) private var modelContext


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

    // Trip yang cocok dengan teks pencarian
    private var filteredTrips: [TripModel] {
        if vm.searchText.isEmpty { return [] }
        let searchLower = vm.searchText.lowercased()
        return allTrips.filter { trip in
            trip.name.lowercased().contains(searchLower)
        }
    }


    // ============================================================
    // MARK: - Body
    // ============================================================

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

                        // SECTION 1: Pilih / Buat Trip
                        tripInfoSection

                        // SECTION 2: Tanggal Perjalanan
                        datePickerSection

                        // SECTION 3: Destinasi (Opsional)
                        destinationSection

                        // SECTION 4: Upload Dokumen
                        documentUploadSection

                        // Tombol Simpan
                        saveButton
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Add Documents")
            .navigationBarTitleDisplayMode(.inline)

            // PDF File Picker
            .fileImporter(
                isPresented: $showPDFPicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: true
            ) { result in
                handlePDFImport(result: result)
            }
        }
    }


    // ============================================================
    // MARK: - SECTION 1: Trip Information
    // ============================================================

    private var tripInfoSection: some View {
        FormCard(title: "Trip Information") {
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


    // ============================================================
    // MARK: - SECTION 2: Date Picker
    // ============================================================

    private var datePickerSection: some View {
        FormCard(title: "Tanggal Perjalanan") {
            VStack(spacing: 15) {
                DatePicker("Tanggal Mulai", selection: $vm.startDate, displayedComponents: .date)
                Divider()
                Toggle("Tambah Durasi", isOn: $vm.isRangeEnabled.animation())
                if vm.isRangeEnabled {
                    Divider()
                    Stepper("\(vm.durationDays) Hari", value: $vm.durationDays, in: 1...30)
                        .fontWeight(.semibold)
                    Text("Kembali: \(vm.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }


    // ============================================================
    // MARK: - SECTION 3: Destination
    // ============================================================

    private var destinationSection: some View {
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


    // ============================================================
    // MARK: - SECTION 4: Document Upload
    // ============================================================

    private var documentUploadSection: some View {
        FormCard(title: "Dokumen") {
            VStack(alignment: .leading, spacing: 16) {

                Text("Upload tiket, KTP, atau dokumen perjalanan lainnya")
                    .font(.body)
                    .foregroundColor(.secondary)

                // Tombol upload (gambar + PDF)
                HStack(spacing: 12) {
                    PhotosPicker(selection: $vm.selectedItems, matching: .images) {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus").font(.title2)
                            Text("Gambar").font(.caption)
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

                // Preview dokumen yang sudah tersimpan sebelumnya
                if !existingDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sudah Tersimpan")
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

                // Dokumen pending (belum disimpan)
                if !vm.pendingDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(vm.totalFileCount) file siap diupload")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)

                        // Gunakan ForEach by ID saja, TANPA index
                        // Ini lebih aman dan tidak crash saat array berubah
                        ForEach(vm.pendingDocuments) { doc in
                            makePendingDocRow(doc: doc)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    // Satu baris dokumen pending
    private func makePendingDocRow(doc: PendingDocument) -> some View {
        // Cari index secara aman setiap kali view dirender
        let safeIndex = vm.pendingDocuments.firstIndex(where: { $0.id == doc.id })

        return HStack(spacing: 10) {

            // Thumbnail
            if doc.isImage, let data = doc.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .cornerRadius(6)
                    .clipped()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "doc.fill")
                        .foregroundColor(.orange)
                }
            }

            // Nama file (bisa diubah)
            if let idx = safeIndex {
                TextField("Nama File", text: Binding(
                    get: {
                        if vm.pendingDocuments.indices.contains(idx) {
                            return vm.pendingDocuments[idx].name
                        }
                        return ""
                    },
                    set: { newValue in
                        if vm.pendingDocuments.indices.contains(idx) {
                            vm.pendingDocuments[idx].name = newValue
                        }
                    }
                ))
                .font(.caption)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled(true)

                // Picker kategori
                Picker("", selection: Binding(
                    get: {
                        if vm.pendingDocuments.indices.contains(idx) {
                            return vm.pendingDocuments[idx].category
                        }
                        return .others
                    },
                    set: { newValue in
                        if vm.pendingDocuments.indices.contains(idx) {
                            vm.pendingDocuments[idx].category = newValue
                        }
                    }
                )) {
                    ForEach(DocumentCategory.allCases, id: \.self) { cat in
                        Label(cat.title, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            // Tombol hapus
            Button {
                vm.pendingDocuments.removeAll { $0.id == doc.id }
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }


    // ============================================================
    // MARK: - Save Button
    // ============================================================

    private var saveButton: some View {
        Button {
            vm.saveTrip(modelContext: modelContext)
            dismiss()
        } label: {
            HStack {
                if vm.isSaving {
                    ProgressView().tint(.white)
                    Text("Menyimpan...")
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Simpan Semua")
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


    // ============================================================
    // MARK: - Helper Functions
    // ============================================================

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
                // PENTING: Baca data file SEKARANG, jangan simpan URL-nya.
                // Karena setelah keluar dari sini, akses ke file bisa hilang.
                let didStart = url.startAccessingSecurityScopedResource()

                // Baca data langsung ke memori
                let pdfData = try? Data(contentsOf: url)

                // Lepas akses security scope setelah selesai baca
                if didStart {
                    url.stopAccessingSecurityScopedResource()
                }

                // Hanya tambahkan jika berhasil baca
                if let data = pdfData {
                    let fileName = url.deletingPathExtension().lastPathComponent
                    let newDoc = PendingDocument(
                        isImage: false,
                        imageData: nil,
                        pdfData: data,
                        name: fileName
                    )
                    vm.pendingDocuments.append(newDoc)
                } else {
                    print("⚠️ Gagal membaca PDF: \(url.lastPathComponent)")
                }
            }

        case .failure(let error):
            print("❌ Gagal membuka PDF picker: \(error.localizedDescription)")
        }
    }
}


// ============================================================
// MARK: - FormCard (Komponen Reusable)
// ============================================================
// Kartu dengan judul dan konten. Dipakai berulang kali agar tampilan rapi.

struct FormCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.leading, 5)

            VStack {
                content
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                radius: 8, x: 0, y: 4
            )
        }
        .padding(.horizontal)
    }
}


#Preview {
    QuickStoreView()
        .modelContainer(
            for: [TripModel.self, DestinationModel.self, DocumentModel.self],
            inMemory: true
        )
}
