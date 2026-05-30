import Foundation
import SwiftData

@Observable
final class ExploreDocumentsViewModel {
    
    // MARK: - Properties
    
    var search: String = ""
    var selectedCategory = "All"
    let categories = ["All", "Identity", "Ticket", "Image", "Documents"]
    
    // MARK: - Methods
    
    func filteredDocuments(from allDocuments: [DocumentModel]) -> [DocumentModel] {
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
        default:
            byCategory = allDocuments
        }

        if search.isEmpty {
            return byCategory
        } else {
            return byCategory.filter { doc in
                doc.name.localizedCaseInsensitiveContains(search)
            }
        }
    }
}
