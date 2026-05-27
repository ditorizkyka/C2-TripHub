import Foundation

// MARK: - Recipe
struct Recipe: Identifiable, Codable {
    let id: UUID
    let title: String
    let author: Author
    let coverImageUrl: URL?
    let portion: Int
    let durationInMinutes: Int
    let ingredientGroups: [IngredientGroup]
    let instructions: [Instruction]
    let tips: String?
}

// MARK: - Author
struct Author: Identifiable, Codable {
    let id: UUID
    let name: String
    let username: String
    let avatarUrl: URL?
}

// MARK: - Ingredient Group
struct IngredientGroup: Identifiable, Codable {
    let id: UUID
    let groupName: String? // Optional: nil jika tidak ada grup (misal hanya 1 list bahan)
    let items: [Ingredient]
}

// MARK: - Ingredient
struct Ingredient: Identifiable, Codable {
    let id: UUID
    let quantity: String
    let name: String
}

// MARK: - Instruction
struct Instruction: Identifiable, Codable {
    let id: UUID
    let sequenceNumber: Int
    let text: String
    let photoUrl: URL?
}
