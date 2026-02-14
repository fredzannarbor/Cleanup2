import Foundation

@MainActor
class DeclutterManager: ObservableObject {
    @Published var items: [DeclutterItem] = []
    @Published var isLoading = false

    private let db = DatabaseService.shared

    func loadItems(forRoom roomId: Int64) {
        isLoading = true
        items = db.fetchItems(forRoom: roomId)
        isLoading = false
    }

    func addItem(roomId: Int64, name: String, category: ItemCategory = .uncategorized, isFurniture: Bool = false, photoPath: String? = nil, notes: String? = nil) {
        _ = db.insertItem(roomId: roomId, name: name, category: category, isFurniture: isFurniture, photoPath: photoPath, notes: notes)
        loadItems(forRoom: roomId)
    }

    func addItems(roomId: Int64, names: [String]) {
        db.insertItems(roomId: roomId, names: names)
        loadItems(forRoom: roomId)
    }

    func categorize(itemId: Int64, category: ItemCategory, roomId: Int64) {
        db.updateItemCategory(id: itemId, category: category)
        loadItems(forRoom: roomId)
    }

    func updateItem(id: Int64, name: String? = nil, category: ItemCategory? = nil, photoPath: String? = nil, notes: String? = nil, roomId: Int64) {
        db.updateItem(id: id, name: name, category: category, photoPath: photoPath, notes: notes)
        loadItems(forRoom: roomId)
    }

    func toggleFurniture(itemId: Int64, isFurniture: Bool, roomId: Int64) {
        db.updateItemFurniture(id: itemId, isFurniture: isFurniture)
        loadItems(forRoom: roomId)
    }

    func deleteItem(id: Int64, roomId: Int64) {
        db.deleteItem(id: id)
        loadItems(forRoom: roomId)
    }

    var uncategorizedItems: [DeclutterItem] {
        items.filter { $0.category == .uncategorized }
    }

    var categorizedItems: [DeclutterItem] {
        items.filter { $0.category != .uncategorized }
    }

    func items(for category: ItemCategory) -> [DeclutterItem] {
        items.filter { $0.category == category }
    }

    /// Parse a voice transcription or comma-separated string into individual item names
    static func parseItemNames(from text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",;\n")
        var names = text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Also split on " and " if commas weren't found
        if names.count == 1 {
            names = text.components(separatedBy: " and ")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }

        return names
    }
}
