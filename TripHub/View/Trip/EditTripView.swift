import SwiftUI
import SwiftData
import PhotosUI

// ============================================================
// MARK: - EditTripView
// ============================================================
// Halaman untuk mengedit semua data sebuah trip.
// Dibuka sebagai .sheet dari TripView.
//
// Yang bisa diedit:
// - Foto sampul
// - Nama trip
// - Deskripsi (opsional)
// - Setiap dokumen yang sudah ada (nama, kategori, atau hapus)

struct EditTripView: View {

    // Trip yang sedang diedit (dari SwiftData)
    // @Bindable supaya kita bisa baca propertinya secara reaktif
    @Bindable var trip: TripModel

    // Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // ViewModel — dibuat sekali saat view muncul, berisi salinan data trip
    @State private var vm: TripEditViewModel

    // ─── Init ─────────────────────────────────────────────────────────────────
    // Kita harus pakai custom init karena @State tidak bisa diisi dari parameter
    // secara langsung. Trik: pakai _vm = State(wrappedValue: ...)
    init(trip: TripModel) {
        self.trip = trip
        _vm = State(wrappedValue: TripEditViewModel(trip: trip))
    }

    // =========================================================================
    // MARK: - Body
    // =========================================================================

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── 1. Cover Image ───────────────────────────────────────
                    coverImageSection

                    // ── 2. Trip Name ─────────────────────────────────────────
                    tripNameSection

                    // ── 3. Description ───────────────────────────────────────
                    descriptionSection

                    // ── 4. Documents ─────────────────────────────────────────
                    documentsSection
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button (kiri)
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        // Jika ada perubahan, tanya dulu
                        if vm.hasChanges {
                            vm.showDiscardConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.primary)
                }

                // Save button (kanan)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        vm.showSaveConfirmation = true
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(vm.canSave ? Color.primaryGreen : .gray)
                    .disabled(!vm.canSave)
                }
            }
            // ─── Dialog: Konfirmasi Simpan ─────────────────────────────────
            .confirmationDialog(
                "Simpan Perubahan?",
                isPresented: $vm.showSaveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Simpan") {
                    vm.saveChanges(to: trip, context: modelContext)
                    dismiss()
                }
                Button("Batal", role: .cancel) { }
            } message: {
                Text("Perubahan yang kamu buat akan disimpan ke trip \"\(trip.name)\".")
            }
            // ─── Dialog: Konfirmasi Buang Perubahan ────────────────────────
            .alert(
                "Buang Perubahan?",
                isPresented: $vm.showDiscardConfirmation
            ) {
                Button("Buang", role: .destructive) {
                    dismiss()
                }
                Button("Kembali Edit", role: .cancel) { }
            } message: {
                Text("Semua perubahan yang belum disimpan akan hilang.")
            }
            // ─── Cegah swipe-to-dismiss jika ada perubahan belum tersimpan ──
            .interactiveDismissDisabled(vm.hasChanges)
            // Saat user swipe dismiss tapi ditolak, tampilkan dialog buang
            // (iOS akan handle interactiveDismissDisabled secara otomatis)
        }
    }

    // =========================================================================
    // MARK: – Section Views
    // =========================================================================

    // ── Cover Image ────────────────────────────────────────────────────────────

    private var coverImageSection: some View {
        EditCard(title: "Cover Image") {
            VStack(spacing: 12) {
                // Preview gambar saat ini
                if let data = vm.coverImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    // Placeholder jika belum ada gambar
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primaryGreen.opacity(0.1))
                            .frame(height: 130)
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.primaryGreen)
                            Text("Belum ada foto sampul")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Tombol ganti foto
                PhotosPicker(selection: $vm.coverImagePickerItem, matching: .images) {
                    Label(
                        vm.coverImageData != nil ? "Ganti Foto" : "Pilih Foto",
                        systemImage: "photo.badge.plus"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.primaryGreen.opacity(0.1))
                    .cornerRadius(10)
                }
                // Saat item berubah, load datanya secara async
                .onChange(of: vm.coverImagePickerItem) { _, _ in
                    Task { await vm.loadSelectedPhoto() }
                }

                // Tombol hapus foto (hanya muncul jika sudah ada gambar)
                if vm.coverImageData != nil {
                    Button(role: .destructive) {
                        vm.coverImageData = nil
                        vm.coverImagePickerItem = nil
                    } label: {
                        Label("Hapus Foto", systemImage: "trash")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }

    // ── Trip Name ──────────────────────────────────────────────────────────────

    private var tripNameSection: some View {
        EditCard(title: "Nama Trip") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Nama ini akan tampil di halaman utama.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Nama trip...", text: $vm.name)
                    .font(.body)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                // Tampilkan peringatan jika nama kosong
                if vm.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    Label("Nama trip tidak boleh kosong.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    // ── Description ────────────────────────────────────────────────────────────

    private var descriptionSection: some View {
        EditCard(title: "Deskripsi (Opsional)") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ceritakan sedikit tentang trip ini.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // TextEditor dengan placeholder manual
                ZStack(alignment: .topLeading) {
                    if vm.tripDescription.isEmpty {
                        Text("Tulis deskripsi di sini...")
                            .foregroundColor(Color(.placeholderText))
                            .font(.body)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 9)
                    }
                    TextEditor(text: $vm.tripDescription)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
    }

    // ── Documents ──────────────────────────────────────────────────────────────

    @ViewBuilder
    private var documentsSection: some View {
        EditCard(title: "Dokumen") {
            VStack(alignment: .leading, spacing: 0) {
                // Jika tidak ada dokumen
                if vm.editedDocuments.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.gray)
                        Text("Belum ada dokumen di trip ini.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                } else {
                    // Daftar dokumen yang bisa diedit
                    ForEach(vm.editedDocuments) { editedDoc in
                        // Lewati yang sudah ditandai untuk dihapus
                        if !editedDoc.isMarkedForDeletion {
                            DocumentEditRow(editedDoc: editedDoc)
                            Divider().padding(.leading, 50)
                        }
                    }

                    // Tampilkan dokumen yang akan dihapus
                    let markedDocs = vm.editedDocuments.filter { $0.isMarkedForDeletion }
                    if !markedDocs.isEmpty {
                        Divider()
                        Text("Akan dihapus saat disimpan:")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 8)

                        ForEach(markedDocs) { editedDoc in
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 30)
                                Text(editedDoc.name)
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                Spacer()
                                // Tombol untuk batalkan penghapusan
                                Button("Batalkan") {
                                    editedDoc.isMarkedForDeletion = false
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
    }
}

// ============================================================
// MARK: - DocumentEditRow
// ============================================================
// Satu baris dokumen yang bisa diedit nama, kategori, dan dihapus.

struct DocumentEditRow: View {
    @Bindable var editedDoc: EditedDocument

    var body: some View {
        HStack(spacing: 12) {
            // Ikon kategori
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBackground)
                    .frame(width: 36, height: 36)
                Image(systemName: editedDoc.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            // Nama & Kategori
            VStack(alignment: .leading, spacing: 4) {
                // TextField untuk nama dokumen
                TextField("Nama dokumen", text: $editedDoc.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                // Picker untuk kategori
                Picker("Kategori", selection: $editedDoc.category) {
                    ForEach(DocumentCategory.allCases, id: \.self) { cat in
                        Label(cat.title, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                .foregroundColor(.secondary)
                .labelsHidden()
                .padding(.leading, -8)
            }

            Spacer()

            // Tombol hapus (tandai untuk dihapus)
            Button {
                editedDoc.isMarkedForDeletion = true
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.vertical, 10)
        // Warna background berubah jika dokumen diubah
        .background(
            editedDoc.hasChanges
            ? Color.orange.opacity(0.05)
            : Color.clear
        )
    }

    // Warna ikon berdasarkan kategori
    private var iconColor: Color {
        switch editedDoc.category {
        case .ticket:   return .blue
        case .identity: return .purple
        case .others:   return .orange
        }
    }

    private var iconBackground: Color {
        iconColor.opacity(0.15)
    }
}

// ============================================================
// MARK: - EditCard (Reusable container)
// ============================================================
// Kartu dengan judul. Mirip FormCard di QuickStoreView tapi
// lebih simpel untuk halaman edit ini.

struct EditCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.leading, 5)

            VStack(alignment: .leading) {
                content
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .padding(.horizontal)
    }
}

// ============================================================
// MARK: - Preview
// ============================================================

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TripModel.self, configurations: config)
    let context = container.mainContext

    let trip = TripModel(
        name: "Liburan Bali",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        tripDescription: "Liburan seru ke Bali bersama keluarga."
    )
    context.insert(trip)

    return EditTripView(trip: trip)
        .modelContainer(container)
}
