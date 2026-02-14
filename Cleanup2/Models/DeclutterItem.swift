import Foundation

struct DeclutterItem: Identifiable {
    let id: Int64
    let roomId: Int64
    let name: String
    let category: ItemCategory
    let isFurniture: Bool
    let photoPath: String?
    let notes: String?
    var sortOrder: Int
    var autoGroup: String?
    let createdAt: Date

    init(id: Int64, roomId: Int64, name: String, category: ItemCategory, isFurniture: Bool, photoPath: String?, notes: String?, sortOrder: Int = 0, autoGroup: String? = nil, createdAt: Date) {
        self.id = id
        self.roomId = roomId
        self.name = name
        self.category = category
        self.isFurniture = isFurniture
        self.photoPath = photoPath
        self.notes = notes
        self.sortOrder = sortOrder
        self.autoGroup = autoGroup
        self.createdAt = createdAt
    }
}
