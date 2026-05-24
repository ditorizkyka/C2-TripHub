import SwiftUI
import SwiftData
import PhotosUI

// ============================================================
// MARK: - QuickStoreView
// ============================================================
// Ini adalah halaman form untuk mengunggah dokumen ke sebuah trip.
// Alur penggunaannya:
// 1. Pilih / buat Trip
// 2. Atur tanggal perjalanan
// 3. (Opsional) Tambah Destinasi khusus
// 4. Upload dokumen (gambar atau PDF)
// 5. Tekan "Simpan"

struct QuickStoreView: View {

    // Ambil semua trip yang sudah tersimpan di database
    @Query var allTrips: [TripModel]

    // ViewModel yang menyimpan state form ini
    @State private var vm = QuickStoreViewModel()

    // Untuk menampilkan file picker PDF
    @State private var showPDFPicker = false

    // Untuk menutup sheet ini
    @Environment(\.dismiss) private var dismiss

    // Warna tema berdasarkan mode gelap/terang
    @Environment(\.colorScheme) private var colorScheme

    // ModelContext diperlukan untuk menyimpan data ke SwiftData
    @Environment(\.modelContext) private var modelContext


    // ============================================================
    // MARK: - Computed Properties (Data Turunan)
    // ============================================================

    // Destinasi yang sudah tersimpan di trip yang dipilih
    private var existingDestinations: [DestinationModel] {
        guard let selectedTrip = vm.selectedTrip else { return [] }
        return selectedTrip.destinations
    }

    // Dokumen yang sudah tersimpan di lokasi yang dipilih (untuk preview)
    private var existingDocuments: [DocumentModel] {
        if let destId = vm.selectedDestinationId {
            // Cek di destinasi existing trip
            if let dest = existingDestinations.first(where: { $0.id == destId }) {
                return dest.documents
            }
            // Cek di destinasi baru yang baru ditambah
            if let dest = vm.destinations.first(where: { $0.id == destId }) {
                return dest.documents
            }
        } else if let trip = vm.selectedTrip {
            return trip.generalDocuments
        }
        return []
    }

    // Daftar nama trip yang cocok dengan teks pencarian
    private var filteredTripSuggestions: [TripModel] {
        guard !vm.searchText.isEmpty else { return [] }
        return allTrips.filter {
            $0.name.lowercased().contains(vm.searchText.lowercased())
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

                        // Keterangan singkat di bagian atas
                        Text("Upload your trip documents and destinations based on your preferences.")
                            .padding(.horizontal)
                            .foregroundStyle(.secondary)
                            .font(.body)

                        // SECTION 1: Pilih / Buat Trip
                        tripInfoSection

                        // SECTION 2: Pilih Tanggal Perjalanan
                        datePickerSection

                        // SECTION 3: Tambah Destinasi (Opsional)
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

            // PDF File Picker (menggunakan sistem Files app)
            .fileImporter(
                isPresented: $showPDFPicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: true
            ) { result in
                handlePDFImport(result: result)
            }
        }
    }


    // ============================================================
    // MARK: - Section Views
    // ============================================================

    // --- Section 1: Info Trip ---
    private var tripInfoSection: some View {
        FormCard(title: "Trip Information") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Select an existing trip or type a new name")
                    .font(.body)
                    .foregroundColor(.secondary)

                // Field pencarian trip
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Find or create a Trip...", text: $vm.searchText)
                        .autocorrectionDisabled(true)
                        .onChange(of: vm.searchText) { _, _ in
                            // Jika user mengetik ulang, batalkan pilihan sebelumnya
                            vm.selectedTrip = nil
                        }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

                // Tampilkan label konfirmasi jika trip sudah dipilih
                if let selectedTrip = vm.selectedTrip {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Trip dipilih: \(selectedTrip.name)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }

                // Tampilkan saran trip dari database
                if !filteredTripSuggestions.isEmpty && vm.selectedTrip == nil {
                    suggestionList
                }

                // Tampilkan info bahwa akan membuat trip baru
                if vm.selectedTrip == nil && !vm.searchText.trimmingCharacters(in: .whitespaces).isEmpty && filteredTripSuggestions.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Akan membuat trip baru: \"\(vm.searchText)\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // --- Daftar saran trip dari database ---
    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
            Text("Pilih dari trip yang ada:")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)

            ForEach(filteredTripSuggestions) { trip in
                Button(action: {
                    // User memilih trip yang sudah ada
                    vm.selectedTrip = trip
                    vm.searchText = trip.name
                    // Sinkronkan tanggal dengan trip yang dipilih
                    vm.startDate = trip.startDate
                    let days = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
                    if days > 0 {
                        vm.isRangeEnabled = true
                        vm.durationDays = days
                    }
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .foregroundColor(.secondary)
                        Text(trip.name)
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Pilih")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                Divider()
            }
        }
        .padding(.top, 4)
    }

    // --- Section 2: Pilih Tanggal ---
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

    // --- Section 3: Destinasi ---
    private var destinationSection: some View {
        FormCard(title: "Destinasi (Opsional)") {
            VStack(spacing: 15) {

                // Penjelasan singkat
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

                // Pilih tanggal destinasi
                DatePicker("Waktu Tiba", selection: $vm.destinationStartDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                DatePicker("Waktu Pergi", selection: $vm.destinationEndDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Tombol tambah destinasi
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

                // Tampilkan destinasi yang baru ditambahkan di form ini
                if !vm.destinations.isEmpty {
                    Divider()
                    Text("Destinasi Baru (belum disimpan)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(vm.destinations) { dest in
                        destinationRow(dest: dest, isExisting: false)
                    }
                }

                // Tampilkan destinasi yang sudah tersimpan di trip yang dipilih
                if !existingDestinations.isEmpty {
                    Divider()
                    Text("Sudah tersimpan di \"\(vm.selectedTrip?.name ?? "")\"")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(existingDestinations) { dest in
                        destinationRow(dest: dest, isExisting: true)
                    }
                }
            }
        }
    }

    // --- Baris satu destinasi ---
    private func destinationRow(dest: DestinationModel, isExisting: Bool) -> some View {
        Button(action: {
            // Toggle pilihan destinasi
            if vm.selectedDestinationId == dest.id {
                vm.selectedDestinationId = nil
            } else {
                vm.selectedDestinationId = dest.id
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dest.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text("\(dest.startTime.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: vm.selectedDestinationId == dest.id ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(vm.selectedDestinationId == dest.id ? .blue : .secondary)
            }
            .padding(10)
            .background(vm.selectedDestinationId == dest.id ? Color.blue.opacity(0.1) : Color(.tertiarySystemFill))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // --- Section 4: Upload Dokumen ---
    private var documentUploadSection: some View {
        FormCard(title: "Dokumen") {
            VStack(alignment: .leading, spacing: 16) {

                // Keterangan
                Text("Upload tiket, KTP, atau dokumen perjalanan lainnya")
                    .font(.body)
                    .foregroundColor(.secondary)

                // Tombol upload
                HStack(spacing: 12) {

                    // Tombol pilih gambar
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

                    // Tombol pilih PDF
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

                // Dokumen yang sudah tersimpan sebelumnya (read-only preview)
                if !existingDocuments.isEmpty {
                    existingDocumentsPreview
                }

                // Dokumen pending yang siap disimpan
                if !vm.pendingDocuments.isEmpty {
                    pendingDocumentsList
                }
            }
        }
    }

    // --- Preview dokumen yang sudah ada ---
    private var existingDocumentsPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sudah Tersimpan Sebelumnya")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ForEach(existingDocuments) { doc in
                HStack(spacing: 10) {
                    // Icon sesuai tipe file
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(doc.isImage ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: doc.isImage ? "photo" : "doc.fill")
                            .foregroundColor(doc.isImage ? .blue : .orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(doc.name).font(.caption).foregroundColor(.primary)
                        Text(doc.category.title).font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .padding(.top, 8)
    }

    // --- List dokumen pending yang siap upload ---
    private var pendingDocumentsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(vm.totalFileCount) file siap diupload")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)

            ForEach(Array(vm.pendingDocuments.enumerated()), id: \.element.id) { index, doc in
                HStack(spacing: 10) {

                    // Thumbnail gambar atau icon PDF
                    if doc.isImage, let img = doc.image {
                        Image(uiImage: img)
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

                    // Field nama file (bisa diubah)
                    TextField("Nama File", text: Binding(
                        get: { vm.pendingDocuments[index].name },
                        set: { newValue in
                            guard vm.pendingDocuments.indices.contains(index) else { return }
                            vm.pendingDocuments[index].name = newValue
                        }
                    ))
                    .font(.caption)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled(true)

                    // Picker kategori
                    Picker("Kategori", selection: Binding(
                        get: { vm.pendingDocuments[index].category },
                        set: { newValue in
                            guard vm.pendingDocuments.indices.contains(index) else { return }
                            vm.pendingDocuments[index].category = newValue
                        }
                    )) {
                        ForEach(DocumentCategory.allCases, id: \.self) { cat in
                            // Tampilkan judul yang mudah dibaca, bukan rawValue
                            Label(cat.title, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()

                    // Tombol hapus
                    Button {
                        let docId = doc.id
                        vm.pendingDocuments.removeAll { $0.id == docId }
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
        .padding(.top, 8)
    }

    // --- Tombol Simpan ---
    private var saveButton: some View {
        Button(action: {
            // Panggil fungsi simpan di ViewModel, sambil kirim modelContext
            vm.saveTrip(modelContext: modelContext)
            dismiss()
        }) {
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
        guard !vm.destinationName.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newDest = DestinationModel(
            name: vm.destinationName.trimmingCharacters(in: .whitespaces),
            startDate: vm.destinationStartDate,
            startTime: vm.destinationStartDate,
            endDate: vm.destinationEndDate,
            endTime: vm.destinationEndDate
        )
        vm.destinations.append(newDest)
        vm.destinationName = ""
    }

    private func handlePDFImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                // Akses security-scoped resource (diperlukan untuk Files app)
                let didStart = url.startAccessingSecurityScopedResource()
                defer {
                    if didStart { url.stopAccessingSecurityScopedResource() }
                }

                let fileName = url.deletingPathExtension().lastPathComponent
                let newDoc = PendingDocument(
                    isImage: false,
                    image: nil,
                    pdfURL: url,
                    name: fileName
                )
                vm.pendingDocuments.append(newDoc)
            }
        case .failure(let error):
            print("❌ Gagal membuka PDF: \(error.localizedDescription)")
        }
    }
}


// ============================================================
// MARK: - FormCard (Komponen Reusable)
// ============================================================
// Sebuah "kartu" dengan judul di atas dan konten di dalam kotak putih.
// Dipakai berulang kali di QuickStoreView agar tampilan konsisten.

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
        .modelContainer(for: [TripModel.self, DestinationModel.self, DocumentModel.self], inMemory: true)
}
