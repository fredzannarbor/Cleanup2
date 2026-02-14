import Foundation

struct DeclutterItem: Identifiable {
    let id: Int64
    let roomId: Int64
    let name: String
    let category: ItemCategory
    let isFurniture: Bool
    let photoPath: String?
    let notes: String?
    let createdAt: Date
}
