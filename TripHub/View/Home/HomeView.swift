//
//  HomeView.swift
//  TripHub
//

import SwiftUI
import SwiftData
import WidgetKit

struct HomeView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties
    @Query(sort: \TripModel.startDate, order: .forward) private var allTrips: [TripModel]
    @State private var vm = HomeViewModel()
    
    @State private var isShowingCamera = false
    @State private var isShowingTripSheet = false
    @State private var capturedImage: UIImage?
    
    @Binding var deepLinkDestination: DeepLinkDestination?
    @Binding var hasPendingSharedFile: Bool
    
    @State private var showQuickStore = false
    @State private var selectedDocument: DocumentModel? = nil
    
    let ongoingGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.secondaryGreen,
            Color.primaryGreen.opacity(0.6)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                if vm.hasNoActiveTrips(from: allTrips) {
                    emptyStateSection
                } else if let trip = vm.featuredTrip(from: allTrips) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            featuredTripSection(trip: trip)
                            categoriesSection(trip: trip)
                            recentDocumentsSection(trip: trip)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    }
                    
                    if let category = vm.deepLinkCategoryNavPath {
                        NavigationLink(
                            destination: CategoryDocuments(trip: trip, category: category, title: category.title),
                            isActive: Binding(
                                get: { vm.deepLinkCategoryNavPath != nil },
                                set: { if !$0 { vm.deepLinkCategoryNavPath = nil } }
                            )
                        ) {
                            EmptyView()
                        }
                        .hidden()
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
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPickerView(image: $capturedImage, onDismiss: {
                    if capturedImage != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isShowingTripSheet = true
                        }
                    }
                })
            }
            .sheet(isPresented: $isShowingTripSheet) {
                if let image = capturedImage {
                    AssignDocumentSheet(capturedImage: image)
                }
            }
            .onAppear {
                vm.syncWidgetData(featuredTrip: vm.featuredTrip(from: allTrips))
                vm.checkForSharedFile { hasPendingSharedFile = false }
            }
            .onChange(of: allTrips.count) { _, _ in
                vm.syncWidgetData(featuredTrip: vm.featuredTrip(from: allTrips))
            }
            .onChange(of: deepLinkDestination) { _, newValue in
                vm.handleDeepLink(newValue, onClear: {
                    deepLinkDestination = nil
                }, onShareTrigger: {
                    vm.checkForSharedFile { hasPendingSharedFile = false }
                })
            }
            .onChange(of: hasPendingSharedFile) { _, newValue in
                if newValue { vm.checkForSharedFile { hasPendingSharedFile = false } }
            }
            .sheet(isPresented: $vm.isShowingSharedFileSheet, onDismiss: {
                vm.sharedFileData = nil
                hasPendingSharedFile = false
            }) {
                if let data = vm.sharedFileData {
                    AssignDocumentSheet(
                        fileData: data,
                        isImage: vm.sharedFileIsImage,
                        originalName: vm.sharedFileOriginalName
                    )
                }
            }
        }
    }

    // MARK: - Sub-Views

    @ViewBuilder
    private var emptyStateSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Image(systemName: "xmark.circle.badge.airplane")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.gray)
            }

            VStack(spacing: 10) {
                Text("No trips on the horizon")
                    .foregroundStyle(.gray)
                    .font(.helveticaCustom(size: 22, weight: .medium))
                    .multilineTextAlignment(.center)

                Text("You have no ongoing or upcoming trips.\nCreate a new trip to save documents here.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    @ViewBuilder
    private func featuredTripSection(trip: TripModel) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                Text(vm.featuredLabel(from: allTrips))
                    .font(.helveticaCustom(size: 23))
            }

            VStack(alignment: .leading, spacing: 15) {
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

                    Text(vm.ongoingTrip(from: allTrips) != nil ? "Ongoing" : "Upcoming")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black)
                        .cornerRadius(15)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.5))
                            .frame(height: 6)

                        Capsule()
                            .fill(Color(hex: "#4AB855"))
                            .frame(
                                width: geo.size.width * vm.tripProgress(for: trip),
                                height: 6
                            )
                            .animation(.easeInOut(duration: 0.6), value: vm.tripProgress(for: trip))
                    }
                }
                .frame(height: 6)

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
                        Text(vm.ongoingTrip(from: allTrips) != nil ? "Arrival date" : "Starts on")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(vm.arrivalText(for: trip))
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

    @ViewBuilder
    private func categoriesSection(trip: TripModel) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Categories")
                .font(.helveticaCustom(size: 23))

            HStack(alignment: .center, spacing: 5) {
                ForEach(DocumentCategory.allCases, id: \.rawValue) { category in
                    HStack {
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

    @ViewBuilder
    private func recentDocumentsSection(trip: TripModel) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent Documents")
                .font(.helveticaCustom(size: 23))

            let recentDocs = trip.allDocuments
                .sorted { $0.uploadDate > $1.uploadDate }
                .prefix(3)

            if recentDocs.isEmpty {
                 Text("No documents for this trip yet.")
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

// MARK: - Previews

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

    return HomeView(deepLinkDestination: .constant(nil), hasPendingSharedFile: .constant(false))
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

    return HomeView(deepLinkDestination: .constant(nil), hasPendingSharedFile: .constant(false))
        .modelContainer(container)
}

#Preview("No Trips") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TripModel.self, configurations: config)

    return HomeView(deepLinkDestination: .constant(nil), hasPendingSharedFile: .constant(false))
        .modelContainer(container)
}
