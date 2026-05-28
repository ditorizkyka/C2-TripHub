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

    let upcomingGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#A8D8EA"),
            Color(hex: "#6CB4D8").opacity(0.7)
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
            ScrollView {
                ZStack {
                    Color.backgroundGray
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Conditional Content ────────────────────────────
                        Group {
                            if hasNoActiveTrips {
                                emptyStateSection
                            } else if let trip = featuredTrip {
                                featuredTripSection(trip: trip)
                                categoriesSection(trip: trip)
                                recentDocumentsSection(trip: trip, )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: {
                        // Camera action
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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
        }
    }

    // =========================================================================
    // MARK: – Sub-Views
    // =========================================================================

    // ── Priority 3: No trips at all ──────────────────────────────────────────

    @ViewBuilder
    private var emptyStateSection: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 60)

            // Illustrated icon
            ZStack {
                Circle()
                    .fill(Color.primaryGreen.opacity(0.12))
                    .frame(width: 120, height: 120)

                Image(systemName: "airplane.departure")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primaryGreen, Color.secondaryGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 10) {
                Text("No trips on the horizon 🌤️")
                    .font(.helveticaCustom(size: 22))
                    .multilineTextAlignment(.center)

                Text("You have no ongoing or upcoming trips.\nWanna create another trip?")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Call-to-action button
            Button(action: {
                showQuickStore = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Create a Trip")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.primaryGreen, Color.secondaryGreen],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.primaryGreen.opacity(0.35), radius: 10, x: 0, y: 6)
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // ── Priority 1 & 2: Featured Trip Card ───────────────────────────────────

    @ViewBuilder
    private func featuredTripSection(trip: TripModel) -> some View {
        VStack(alignment: .leading, spacing: 20) {

            // Section header with status badge
            HStack(alignment: .center) {
                Text(featuredLabel)
                    .font(.helveticaCustom(size: 23))

                Spacer()

                // Live indicator for ongoing trips
                if ongoingTrip != nil {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 7, height: 7)
                            .overlay(
                                Circle()
                                    .fill(Color.red.opacity(0.3))
                                    .frame(width: 14, height: 14)
                            )
                        Text("Live")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 15) {
                // ── Row 1: Destination name & status badge ──
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Trip")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.7))
                        Text(trip.name)
                            .font(.system(size: 18, weight: .bold))
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
                        Text("Documents").font(.caption).foregroundColor(.black.opacity(0.6))
                        Text("\(trip.totalDocumentCount) Doc")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Destination").font(.caption).foregroundColor(.black.opacity(0.6))
                        Text("\(trip.destinations.count) Dest")
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text(ongoingTrip != nil ? "Arrival date" : "Starts on")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.6))
                        Text(arrivalText(for: trip))
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .padding(20)
            .background(ongoingTrip != nil ? ongoingGradient : upcomingGradient)
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

            // Asumsi: TripModel memiliki array dokumen (misal: trip.documents)
            // dan DocumentModel memiliki properti tanggal (misal: createdAt).
            // Sesuaikan nama properti ini dengan schema SwiftData yang kamu buat.
            let allDocuments = trip.generalDocuments ?? []
            
            // Urutkan dari yang paling baru, lalu ambil maksimal 3
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
                        // Pastikan StarredDocumentsCard diperbarui untuk menerima data dokumen
                        
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
