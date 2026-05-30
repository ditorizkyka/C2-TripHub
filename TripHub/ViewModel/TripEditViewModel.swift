import SwiftUI
import SwiftData
import PhotosUI

// MARK: - TripEditViewModel

@Observable
class TripEditViewModel {

    // MARK: - Properties

    var name: String
    var tripDescription: String
    var coverImageData: Data?
    var coverImagePickerItem: PhotosPickerItem? = nil
    var editedDocuments: [EditedDocument] = []

    var showSaveConfirmation = false
    var showDiscardConfirmation = false

    private let originalName: String
    private let originalDescription: String
    private let originalCoverImageData: Data?

    // MARK: - Init

    init(trip: TripModel) {
        self.name              = trip.name
        self.tripDescription   = trip.tripDescription ?? ""
        self.coverImageData    = trip.coverImageData

        self.originalName             = trip.name
        self.originalDescription      = trip.tripDescription ?? ""
        self.originalCoverImageData   = trip.coverImageData

        self.editedDocuments = trip.generalDocuments.map {
            EditedDocument(source: $0)
        }
    }

    // MARK: - Computed Properties

    var hasChanges: Bool {
        let nameChanged        = name.trimmingCharacters(in: .whitespaces) != originalName
        let descChanged        = tripDescription.trimmingCharacters(in: .whitespaces) != originalDescription
        let imageChanged       = coverImageData != originalCoverImageData
        let docsChanged        = editedDocuments.contains { $0.hasChanges }
        let docsDeleted        = editedDocuments.contains { $0.isMarkedForDeletion }

        return nameChanged || descChanged || imageChanged || docsChanged || docsDeleted
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Methods

    func loadSelectedPhoto() async {
        guard let item = coverImagePickerItem else {
            coverImageData = nil
            return
        }

        if let data = try? await item.loadTransferable(type: Data.self) {
            coverImageData = data
        }
    }

    func saveChanges(to trip: TripModel, context: ModelContext) {
        trip.name = name.trimmingCharacters(in: .whitespaces)

        let desc = tripDescription.trimmingCharacters(in: .whitespaces)
        trip.tripDescription = desc.isEmpty ? nil : desc
        trip.coverImageData = coverImageData

        for editedDoc in editedDocuments {
            if editedDoc.isMarkedForDeletion {
                if let source = editedDoc.source {
                    context.delete(source)
                }
            } else {
                editedDoc.source?.name = editedDoc.name
                editedDoc.source?.setCategory(editedDoc.category)
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to save: \(error.localizedDescription)")
        }
    }
}

// MARK: - EditedDocument

@Observable
class EditedDocument: Identifiable {
    let id: UUID
    weak var source: DocumentModel?

    var name: String
    var category: DocumentCategory
    var isMarkedForDeletion: Bool = false

    private let originalName: String
    private let originalCategory: DocumentCategory

    var hasChanges: Bool {
        name != originalName || category != originalCategory
    }

    init(source: DocumentModel) {
        self.id               = source.id
        self.source           = source
        self.name             = source.name
        self.category         = source.getCategory()
        self.originalName     = source.name
        self.originalCategory = source.getCategory()
    }
}
