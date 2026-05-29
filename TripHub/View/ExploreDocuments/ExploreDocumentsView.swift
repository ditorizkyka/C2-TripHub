//
//  ExploreDocumentsView.swift
//  TripHub
//
//  Created by Andito Rizkyka Rianto on 12/05/26.
//

import SwiftUI
import SwiftData
import QuickLook

// ============================================================
// MARK: - ExploreDocumentsView
// Halaman utama untuk melihat semua dokumen yang tersimpan.
//
// Fitur:
// - Chip filter (All / Identity / Ticket / Image / Documents)
// - Search bar untuk mencari nama dokumen
// - Grid 3 kolom seperti iOS Files app
// - Tap dokumen untuk preview
// - Tombol + untuk upload dokumen baru
// ============================================================

struct ExploreDocumentsView: View {

    // --- State ---
    @State private var search: String = ""
    @State private var selectedCategory = "All"
    @State private var selectedDocument: DocumentModel? = nil   // Dokumen yang akan di-preview
    @State private var showQuickStore = false                    // Untuk membuka form upload

    // --- SwiftData ---
    @Environment(\.modelContext) private var modelContext
    @Query var allDocuments: [DocumentModel]

    // --- Konstanta ---
    let categories = ["All", "Identity", "Ticket", "Image", "Documents"]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    // ============================================================
    // MARK: - Filter Logic
    // Dokumen yang ditampilkan = filter kategori chip + filter search
    // ============================================================
    var filteredDocuments: [DocumentModel] {
        // Step 1: Filter berdasarkan chip yang dipilih
        let byCategory: [DocumentModel]
        switch selectedCategory {
        case "Identity":
            byCategory = allDocuments.filter { $0.getCategory() == .identity }
        case "Ticket":
            byCategory = allDocuments.filter { $0.getCategory() == .ticket }
        case "Image":
            byCategory = allDocuments.filter { $0.isImage }
        case "Documents":
            byCategory = allDocuments.filter { !$0.isImage }
        default: // "All"
            byCategory = allDocuments
        }

        // Step 2: Filter berdasarkan teks pencarian
        if search.isEmpty {
            return byCategory
        } else {
            return byCategory.filter { doc in
                doc.name.localizedCaseInsensitiveContains(search)
            }
        }
    }

    // ============================================================
    // MARK: - Body
    // ============================================================
    var body: some View {
        NavigationStack {
            ScrollView {

                // ── 1. Chip Filter ─────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            ChipItemView(
                                title: category,
                                isSelected: selectedCategory == category
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                // ── 2. Grid Dokumen ────────────────────────────
                if filteredDocuments.isEmpty {
                    // Tampilkan pesan kosong
                    VStack(spacing: 18) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(.gray)
                        
                        VStack(spacing: 10) {
                            Text("No documents found")
                                .font(.helveticaCustom(size: 22, weight: .medium))
                                .foregroundStyle(.gray)
                            
                            Text("You haven't uploaded any documents\nthat match this filter.")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)

                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredDocuments) { doc in
                            DocumentCardView(document: doc) {
                                // Tap → buka preview
                                selectedDocument = doc
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }

            // ── Sheet: Preview dokumen ─────────────────────────
            // PENTING: .sheet harus di sini (di luar ScrollView/Grid), bukan di dalam
            .sheet(item: $selectedDocument) { doc in
                DocumentPreviewView(document: doc)
            }

            // ── Sheet: Form upload dokumen baru ───────────────
            .sheet(isPresented: $showQuickStore) {
                QuickStoreView()
            }

            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Documents")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Tombol + untuk upload dokumen baru
                    Button {
                        showQuickStore = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color(hex: "#4AB855"))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

// ============================================================
// MARK: - DocumentCardView
// Satu sel di dalam grid — mirip tampilan iOS Files app.
// Tap → buka preview. Long-press → menu pin/hapus.
// ============================================================

struct DocumentCardView: View {
    @Bindable var document: DocumentModel
    @Environment(\.modelContext) private var modelContext
    var onTap: () -> Void   // Callback ketika user tap kartu ini

    var body: some View {
        Button(action: { onTap() }) {
            VStack(spacing: 6) {

                // Thumbnail file
                DocumentThumbnailView(document: document)
                    // 👇 FIX 1: Set width dan height menggunakan nilai yang sama agar selalu kotak sempurna (1:1)
                    .frame(width: thumbnailSize, height: thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    .overlay(alignment: .topTrailing) {
                        // Pin badge di sudut kanan atas
                        if document.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.helveticaCustom(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color(hex: "#4AB855"))
                                .clipShape(Circle())
                                .offset(x: 5, y: -5)
                        }
                    }

                // Nama dokumen
                Text(document.name)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    // 👇 FIX 2: Kunci tinggi teks untuk 2 baris (sekitar 34pt) dan ratakan ke atas.
                    // Ini mencegah tanggal di bawahnya naik-turun jika judul hanya 1 baris.
                    .frame(height: 34, alignment: .top)

                // Tanggal upload
                Text(document.uploadDate, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            // 👇 Opsional tapi penting: Kunci lebar VStack sebesar thumbnail
            // agar teks panjang ikut terpotong (wrap) rapi menyesuaikan lebar gambar.
            .frame(width: thumbnailSize)
        }
        .buttonStyle(.plain)
        // Long-press menu
        .contextMenu {
            Button {
                document.isPinned.toggle()
                try? modelContext.save()
            } label: {
                Label(
                    document.isPinned ? "Unpin" : "Pin",
                    systemImage: document.isPinned ? "pin.slash" : "pin"
                )
            }

            Divider()

            Button(role: .destructive) {
                modelContext.delete(document)
                try? modelContext.save()
            } label: {
                Label("Hapus", systemImage: "trash")
            }
        }
    }

    // Ukuran thumbnail menyesuaikan layar (lebar kolom)
    private var thumbnailSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        // (lebar layar - padding kiri-kanan - jarak antar kolom) / 3 kolom
        return (screenWidth - 32 - 32) / 3
    }
}

// ============================================================
// MARK: - DocumentThumbnailView
// Gambar: tampilkan thumbnail asli.
// PDF/file lain: tampilkan ikon berwarna sesuai kategori.
// ============================================================

struct DocumentThumbnailView: View {
    let document: DocumentModel

    var body: some View {
        // Coba load gambar jika ini file gambar
        if document.isImage, let image = loadImageFromDisk(fileName: document.fileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            // Tampilkan ikon berwarna untuk PDF / dokumen lain
            ZStack {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                       

                    // Label ekstensi file (misal: "PDF", "JPG")
                    Text(fileExtension.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // Ekstensi file, contoh: "pdf", "jpg"
    private var fileExtension: String {
        (document.fileName as NSString).pathExtension
    }

    // Ikon SF Symbols berdasarkan kategori
    private var iconName: String {
        switch document.getCategory() {
        case .ticket:   return "airplane.circle"
        case .identity: return "person.text.rectangle"
        case .others:   return "doc.richtext"
        }
    }

    // Warna gradient berdasarkan kategori
    private var gradientColors: [Color] {
        switch document.getCategory() {
        case .ticket:   return [Color(hex: "#4AB855"), Color(hex: "#2d8c3e")]
        case .identity: return [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")]
        case .others:   return [Color(hex: "#EF4444"), Color(hex: "#B91C1C")]
        }
    }

    // Cari file gambar di seluruh subfolder Documents
    private func loadImageFromDisk(fileName: String) -> UIImage? {
        let fm = FileManager.default
        guard let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        // Coba langsung di root folder Documents
        let directURL = docsDir.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: directURL), let img = UIImage(data: data) {
            return img
        }

        // Cari di semua subfolder (struktur: TripName/DestinationName/fileName)
        if let enumerator = fm.enumerator(at: docsDir, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator {
                if url.lastPathComponent == fileName {
                    if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                        return img
                    }
                }
            }
        }

        return nil
    }
}

// ============================================================
// MARK: - DocumentPreviewView
// Sheet preview ketika user tap sebuah dokumen.
// - Gambar: tampilkan foto full screen
// - PDF: buka native QuickLook viewer
// ============================================================

struct DocumentPreviewView: View {
    let document: DocumentModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if document.isImage {
                    ImageFullView(document: document)
                } else {
                    PDFPreviewView(document: document)
                }
            }
            .navigationTitle(document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tutup") { dismiss() }
                        .foregroundColor(Color(hex: "#4AB855"))
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// ── Gambar full screen (bisa di-zoom) ──────────────────────

struct ImageFullView: View {
    let document: DocumentModel
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Group {
            if let image = findImage(fileName: document.fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in scale = max(1.0, value) }
                            .onEnded   { _ in withAnimation { scale = 1.0 } }
                    )
                    .padding()
            } else {
                ContentUnavailableView(
                    "Gambar tidak ditemukan",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("File mungkin sudah dihapus atau dipindahkan.")
                )
            }
        }
    }

    private func findImage(fileName: String) -> UIImage? {
        let fm = FileManager.default
        guard let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }

        // Coba root
        let direct = docsDir.appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: direct), let img = UIImage(data: data) { return img }

        // Cari di subfolder
        if let enumerator = fm.enumerator(at: docsDir, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator where url.lastPathComponent == fileName {
                if let data = try? Data(contentsOf: url), let img = UIImage(data: data) { return img }
            }
        }
        return nil
    }
}

// ── PDF dengan QuickLook (native iOS) ──────────────────────

struct PDFPreviewView: UIViewControllerRepresentable {
    let document: DocumentModel

    func makeUIViewController(context: Context) -> QLPreviewController {
        let vc = QLPreviewController()
        vc.dataSource = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(document: document)
    }

    // Coordinator menyediakan file URL ke QLPreviewController
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let document: DocumentModel

        init(document: DocumentModel) {
            self.document = document
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            findFileURL() as QLPreviewItem
        }

        // Cari URL file di disk
        private func findFileURL() -> NSURL {
            let fm = FileManager.default
            guard let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return NSURL()
            }

            let fileName = document.fileName

            // Coba root
            let directURL = docsDir.appendingPathComponent(fileName)
            if fm.fileExists(atPath: directURL.path) { return directURL as NSURL }

            // Cari di subfolder
            if let enumerator = fm.enumerator(at: docsDir, includingPropertiesForKeys: nil) {
                for case let url as URL in enumerator where url.lastPathComponent == fileName {
                    if fm.fileExists(atPath: url.path) { return url as NSURL }
                }
            }

            return NSURL()
        }
    }
}

// ============================================================
// MARK: - Preview
// ============================================================

#Preview {
    ExploreDocumentsView()
        .modelContainer(for: [TripModel.self, DestinationModel.self, DocumentModel.self], inMemory: true)
}
