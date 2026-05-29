import Foundation
import SwiftUI
import SwiftData
import PhotosUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDocument: DocumentModel? = nil
    // ─── SwiftData Query ───────────────────────────────────────────────────────
    /// Fetch all trips sorted by start date (soonest first)
    @Query(sort: \TripModel.startDate, order: .forward) private var allTrips: [TripModel]
    
    @State private var isShowingCamera = false
    @State private var isShowingTripSheet = false
    @State private var capturedImage: UIImage?

    // ─── Local UI State ────────────────────────────────────────────────────────
    @State private var showQuickStore = false
//    @State private var selectedDocument: DocumentModel? = nil
    // ─── Gradients ─────────────────────────────────────────────────────────────
    let ongoingGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.secondaryGreen,
            Color.primaryGreen.opacity(0.6)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    

    // =========================================================================
    // MARK: – Trip Classification Methods
    // =========================================================================

    /// Priority 1 – A trip whose date range covers today.
    private var ongoingTrip: TripModel? {
        allTrips.first { $0.isOngoing(at: Date()) }
    }

    /// Priority 2 – The next upcoming trip (earliest start date in the future).
    private var upcomingTrip: TripModel? {
        allTrips
            .filter { $0.isUpcoming(at: Date()) }
            .sorted { $0.normalizedStart() < $1.normalizedStart() }
            .first
    }

    /// True when neither ongoing nor upcoming trips exist.
    private var hasNoActiveTrips: Bool {
        ongoingTrip == nil && upcomingTrip == nil
    }

    /// The trip that is currently featured (ongoing takes priority over upcoming).
    private var featuredTrip: TripModel? {
        ongoingTrip ?? upcomingTrip
    }

    /// Human-readable label shown above the featured card.
    private var featuredLabel: String {
        ongoingTrip != nil ? "Ongoing Trip" : "Upcoming Trip"
    }

    /// Color-coded progress along the trip timeline (0.0 – 1.0).
    /// - For ongoing: percentage of days elapsed.
    /// - For upcoming: always 0 (not started yet).
    private func tripProgress(for trip: TripModel) -> Double {
        guard trip.isOngoing(at: Date()) else { return 0.0 }
        let totalDays = trip.endDate.timeIntervalSince(trip.startDate)
        let elapsed   = Date().timeIntervalSince(trip.startDate)
        guard totalDays > 0 else { return 1.0 }
        return min(max(elapsed / totalDays, 0), 1)
    }

    /// Short human-readable "arrival" string for the featured card.
    private func arrivalText(for trip: TripModel) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: trip.endDate)
    }

    // =========================================================================
    // MARK: – Body
    // =========================================================================

    var body: some View {
            NavigationStack {
                ZStack {
                    
                    
                    // 2. Pisahkan logika di sini (di luar ScrollView)
                    if hasNoActiveTrips {
                        // Tampil di tengah persis tanpa ScrollView
                        emptyStateSection
                    } else if let trip = featuredTrip {
                        // Gunakan ScrollView hanya jika ada data trip
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                featuredTripSection(trip: trip)
                                categoriesSection(trip: trip)
                                recentDocumentsSection(trip: trip) // typo koma sudah diperbaiki
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .padding(.bottom, 40)
                        }
                    }
                }
                .navigationTitle("Home")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button(action: {
                            isShowingCamera = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 4)
                        }

                        Button(action: {
                            showQuickStore = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color(hex: "#4AB855"))
                                .clipShape(Circle())
                        }
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .sheet(isPresented: $showQuickStore) {
                    QuickStoreView()
                }
                .sheet(item: $selectedDocument) { doc in
                    DocumentPreviewView(document: doc)
                }
                // Menampilkan Kamera
                        .fullScreenCover(isPresented: $isShowingCamera) {
                            CameraPickerView(image: $capturedImage, onDismiss: {
                                // Beri sedikit jeda agar kamera selesai menutup sebelum memunculkan sheet
                                if capturedImage != nil {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        isShowingTripSheet = true
                                    }
                                }
                            })
                        }
                        // Menampilkan Sheet Pemilihan Trip
                        .sheet(isPresented: $isShowingTripSheet) {
                            if let image = capturedImage {
                                AssignTripSheet(capturedImage: image)
                            }
                        }
            }
        }

    // =========================================================================
    // MARK: – Sub-Views
    // =========================================================================

    // ── Priority 3: No trips at all ──────────────────────────────────────────

    @ViewBuilder
        private var emptyStateSection: some View {
            VStack(spacing: 18) {
                // Hapus Spacer() di sini karena sudah otomatis ke tengah
                
                // Illustrated icon
                ZStack {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            .gray
                        )
                }

                VStack(spacing: 10) {
                    Text("No trips on the horizon")
                        .foregroundStyle(.gray)
                        .font(.helveticaCustom(size: 22, weight: .medium))
                        .multilineTextAlignment(.center)

                    Text("You have no ongoing or upcoming trips.\nCreate new Trip to save Documents here.")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
             
            }
            // Tambahkan modifier ini agar view mengambil seluruh ruang layar dan menjebak konten di tengah
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

    // ── Priority 1 & 2: Featured Trip Card ───────────────────────────────────

    @ViewBuilder
    private func featuredTripSection(trip: TripModel) -> some View {
        VStack(alignment: .leading, spacing: 20) {

            // Section header with status badge
            HStack(alignment: .center) {
                Text(featuredLabel)
                    .font(.helveticaCustom(size: 23))

                
            }

            VStack(alignment: .leading, spacing: 15) {
                // ── Row 1: Destination name & status badge ──
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Trip")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text(trip.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Text(ongoingTrip != nil ? "On Going" : "Upcoming")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .cornerRadius(15)
                }

                // ── Row 2: Progress bar (only meaningful for ongoing) ──
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 6)

                        Capsule()
                            .fill(Color(hex: "#4AB855"))
                            .frame(
                                width: geo.size.width * tripProgress(for: trip),
                                height: 6
                            )
                            .animation(.easeInOut(duration: 0.6), value: tripProgress(for: trip))
                    }
                }
                .frame(height: 6)

                // ── Row 3: Stats ──
                HStack {
                    VStack(alignment: .leading) {
                        Text("Documents").font(.caption).foregroundColor(.secondary)
                        Text("\(trip.totalDocumentCount) Doc")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Destination").font(.caption).foregroundColor(.secondary)
                        Text("\(trip.destinations.count) Dest")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(ongoingTrip != nil ? "Arrival date" : "Starts on")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(arrivalText(for: trip))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(20)
            .background(ongoingGradient)
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        }
    }

    // ── Categories Section ────────────────────────────────────────────────────

    @ViewBuilder
    private func categoriesSection(trip: TripModel) -> some View { // <- Tambahkan parameter trip
        VStack(alignment: .leading, spacing: 20) {
            Text("Categories")
                .font(.helveticaCustom(size: 23))

            HStack(alignment: .center, spacing: 5) {
                ForEach(DocumentCategory.allCases, id: \.rawValue) { category in
                    HStack {
                        // Kirim trip dan category ke halaman CategoryDocuments
                        NavigationLink(destination: CategoryDocuments(trip: trip, category: category, title: category.title)) {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: category.icon)
                                    .font(.title2)
                                    .fontWeight(.light)

                                Text(category.title)
                                    .font(.helveticaCustom(size: 18))
                            }
                            .padding(.vertical, 13)
                            .padding(.horizontal, 20)
                            .foregroundColor(.primary)
                        }

                        Spacer()
                    }
                    .frame(maxHeight: 100)
                    .background(Color.primaryGray)
                    .cornerRadius(20)
                }
            }
        }
    }

    // ── Recent Documents Section ──────────────────────────────────────────────

    // ── Recent Documents Section ──────────────────────────────────────────────
    
    
    @ViewBuilder
    private func recentDocumentsSection(trip: TripModel) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent Documents")
                .font(.helveticaCustom(size: 23))

            // 1. Ambil dokumen umum
            let generalDocs = trip.generalDocuments
            
            // 2. Ambil dan gabungkan semua dokumen dari seluruh destinasi
            let destDocs = trip.destinations.flatMap { $0.documents }
            
            // 3. Gabungkan kedua sumber dokumen tersebut menjadi satu array utuh
            let allDocuments = generalDocs + destDocs
            
            // 4. Urutkan dari yang paling baru, lalu ambil maksimal 3
            let recentDocs = allDocuments
                .sorted { $0.uploadDate > $1.uploadDate }
                .prefix(3)

            if recentDocs.isEmpty {
                 Text("Belum ada dokumen untuk trip ini.")
                     .font(.system(size: 15))
                     .foregroundColor(.gray)
                     .padding(.top, 10)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(recentDocs) { document in
                        Button {
                            selectedDocument = document
                        } label: {
                            StarredDocumentsCard(document: document)
                        }
                    }
                }
            }
        }
    }
}

// =========================================================================
// MARK: – Preview
// =========================================================================

struct AssignTripSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    var capturedImage: UIImage
    
    @State private var vm = QuickStoreViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        FormCard(title: "Preview Dokumen") {
                            VStack(alignment: .leading, spacing: 16) {
                                Image(uiImage: capturedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 250)
                                    .cornerRadius(10)
                                    .padding(.vertical, 8)
                                    
                                if !vm.pendingDocuments.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Detail Dokumen")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                        
                                        ForEach($vm.pendingDocuments) { $doc in
                                            QuickStoreView.SwipeablePendingDocRow(
                                                document: $doc,
                                                onDelete: {
                                                    dismiss()
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        TripFieldStoreData(vm: vm)
                        
                        DestinationFieldStoreData(vm: vm)
                        
                        // Tombol Simpan
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
                                    Text("Simpan Dokumen")
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
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 10)
                }
            }
            .navigationTitle("Detail Dokumen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if vm.pendingDocuments.isEmpty {
                    if let jpegData = capturedImage.jpegData(compressionQuality: 0.8) {
                        let newDoc = PendingDocument(
                            isImage: true,
                            imageData: jpegData,
                            pdfData: nil,
                            name: "Captured_Photo"
                        )
                        vm.pendingDocuments.append(newDoc)
                    }
                }
            }
        }
        .presentationDetents([.large]) // Use large to give enough space for the form
    }
}

#Preview("Ongoing Trip") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TripModel.self, configurations: config)
    let context = container.mainContext

    let ongoing = TripModel(
        name: "Bandung Indonesia",
        startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!
    )
    context.insert(ongoing)

    return HomeView()
        .modelContainer(container)
}

#Preview("Upcoming Trip") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TripModel.self, configurations: config)
    let context = container.mainContext

    let upcoming = TripModel(
        name: "Bali Vacation",
        startDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
        endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!
    )
    context.insert(upcoming)

    return HomeView()
        .modelContainer(container)
}

#Preview("No Trips") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TripModel.self, configurations: config)

    return HomeView()
        .modelContainer(container)
}

