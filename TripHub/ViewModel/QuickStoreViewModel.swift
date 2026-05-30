import SwiftUI
import PhotosUI
import SwiftData

// MARK: - PendingDocument

struct PendingDocument: Identifiable {
    let id = UUID()
    var isImage: Bool
    var imageData: Data?
    var pdfData: Data?
    var name: String
    var category: DocumentCategory = .others
}

// MARK: - QuickStoreViewModel

@MainActor
@Observable
class QuickStoreViewModel {
    
    // MARK: - Properties
    
    var searchText: String = ""
    var selectedTrip: TripModel? = nil
    var startDate = Date()
    var isRangeEnabled = false
    var durationDays = 1

    var tripDescription: String = ""
    var coverImageData: Data? = nil

    var endDate: Date {
        return Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
    }

    var destinationName: String = ""
    var destinationStartDate = Date()
    var destinationEndDate = Date()
    var newDestinations: [DestinationModel] = []
    var selectedDestinationId: UUID? = nil

    var pendingDocuments: [PendingDocument] = []

    var selectedItems: [PhotosPickerItem] = [] {
        didSet {
            if selectedItems.isEmpty { return }
            let itemsToProcess = selectedItems
            DispatchQueue.main.async {
                self.selectedItems = []
            }
            loadImages(itemsToProcess)
        }
    }

    var isSaving = false
    var showSaveSuccess = false

    var totalFileCount: Int {
        return pendingDocuments.count
    }

    var canSave: Bool {
        let hasTrip = selectedTrip != nil || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        let hasDocs = !pendingDocuments.isEmpty
        return hasTrip && hasDocs
    }

    // MARK: - Methods

    func saveTrip(modelContext: ModelContext) {
        isSaving = true

        let tripName: String
        if let existing = selectedTrip {
            tripName = existing.name
        } else {
            tripName = searchText.trimmingCharacters(in: .whitespaces)
        }

        if tripName.isEmpty {
            isSaving = false
            return
        }

        let finalEndDate: Date
        if isRangeEnabled {
            finalEndDate = endDate
        } else {
            finalEndDate = startDate
        }

        let tripTarget: TripModel
        if let existing = selectedTrip {
            tripTarget = existing
        } else {
            let desc = tripDescription.trimmingCharacters(in: .whitespaces)
            let newTrip = TripModel(
                name: tripName,
                startDate: startDate,
                endDate: finalEndDate,
                tripDescription: desc.isEmpty ? nil : desc,
                coverImageData: coverImageData
            )
            modelContext.insert(newTrip)
            tripTarget = newTrip
        }

        for dest in newDestinations {
            modelContext.insert(dest)
            dest.trip = tripTarget
        }

        var targetDestination: DestinationModel? = nil
        var targetDestinationName: String? = nil

        if let destId = selectedDestinationId {
            if let found = tripTarget.destinations.first(where: { $0.id == destId }) {
                targetDestination = found
                targetDestinationName = found.name
            }
            if targetDestination == nil {
                if let found = newDestinations.first(where: { $0.id == destId }) {
                    targetDestination = found
                    targetDestinationName = found.name
                }
            }
        }

        for (index, pendingDoc) in pendingDocuments.enumerated() {
            let fileExtension: String
            if pendingDoc.isImage {
                fileExtension = "jpg"
            } else {
                fileExtension = "pdf"
            }

            let uniqueFileName = "\(UUID().uuidString).\(fileExtension)"

            let displayName: String
            let trimmedName = pendingDoc.name.trimmingCharacters(in: .whitespaces)
            if trimmedName.isEmpty {
                displayName = "\(tripName)_doc_\(index + 1)"
            } else {
                displayName = trimmedName
            }

            let fileData: Data?
            if pendingDoc.isImage {
                fileData = pendingDoc.imageData
            } else {
                fileData = pendingDoc.pdfData
            }

            guard let data = fileData else {
                continue
            }

            LocalFileManager.shared.saveDocument(
                data: data,
                fileName: uniqueFileName,
                tripName: tripName,
                destinationName: targetDestinationName
            )

            let fileSizeMB = Double(data.count) / (1024.0 * 1024.0)

            let newDoc = DocumentModel(
                name: displayName,
                uploadDate: Date(),
                size: fileSizeMB,
                category: pendingDoc.category,
                fileName: uniqueFileName
            )
            modelContext.insert(newDoc)

            if let dest = targetDestination {
                newDoc.destination = dest
            } else {
                newDoc.trip = tripTarget
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save to database: \(error.localizedDescription)")
        }

        resetForm()
        isSaving = false
        showSaveSuccess = true
    }

    private func loadImages(_ items: [PhotosPickerItem]) {
        for item in items {
            item.loadTransferable(type: Data.self) { [weak self] result in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }

                    switch result {
                    case .success(let data):
                        guard let data = data else { return }
                        guard let image = UIImage(data: data) else { return }

                        let jpegData = image.jpegData(compressionQuality: 0.8)

                        let docName = "Image_\(self.pendingDocuments.count + 1)"
                        let newDoc = PendingDocument(
                            isImage: true,
                            imageData: jpegData,
                            pdfData: nil,
                            name: docName
                        )
                        self.pendingDocuments.append(newDoc)

                    case .failure(let error):
                        print("Failed to load image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func resetForm() {
        searchText = ""
        selectedTrip = nil
        startDate = Date()
        isRangeEnabled = false
        durationDays = 1
        tripDescription = ""
        coverImageData = nil
        destinationName = ""
        newDestinations = []
        destinationStartDate = Date()
        destinationEndDate = Date()
        selectedDestinationId = nil
        pendingDocuments = []
    }
}
