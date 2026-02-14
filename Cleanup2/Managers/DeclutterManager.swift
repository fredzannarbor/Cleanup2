import Foundation

enum SortMode: String, CaseIterable {
    case alphabetical
    case dateAdded
    case custom

    var label: String {
        switch self {
        case .alphabetical: return "A-Z"
        case .dateAdded: return "Date Added"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .alphabetical: return "textformat.abc"
        case .dateAdded: return "calendar"
        case .custom: return "arrow.up.arrow.down"
        }
    }
}

@MainActor
class DeclutterManager: ObservableObject {
    @Published var items: [DeclutterItem] = []
    @Published var isLoading = false
    @Published var sortMode: SortMode = .alphabetical
    @Published var isAutogrouped = false

    private let db = DatabaseService.shared

    func loadItems(forRoom roomId: Int64) {
        isLoading = true
        items = db.fetchItems(forRoom: roomId)
        applySorting()
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

    // MARK: - Sorting

    func applySorting() {
        switch sortMode {
        case .alphabetical:
            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .dateAdded:
            items.sort { $0.createdAt > $1.createdAt }
        case .custom:
            items.sort { $0.sortOrder < $1.sortOrder }
        }
    }

    // MARK: - Drag to Reorder

    func moveItems(in category: ItemCategory, from source: IndexSet, to destination: Int, roomId: Int64) {
        var categoryItems = items(for: category)
        categoryItems.move(fromOffsets: source, toOffset: destination)
        for (index, item) in categoryItems.enumerated() {
            db.updateItemSortOrder(id: item.id, sortOrder: index)
        }
        sortMode = .custom
        loadItems(forRoom: roomId)
    }

    // MARK: - Autogroup

    func autogroupItems(roomId: Int64) {
        let keywords = extractKeywordGroups()
        for item in items {
            let group = keywords.first { keyword in
                item.name.localizedCaseInsensitiveContains(keyword)
            }
            db.updateItemAutoGroup(id: item.id, autoGroup: group?.capitalized)
        }
        isAutogrouped = true
        loadItems(forRoom: roomId)
    }

    func clearAutogroups(roomId: Int64) {
        for item in items {
            db.updateItemAutoGroup(id: item.id, autoGroup: nil)
        }
        isAutogrouped = false
        loadItems(forRoom: roomId)
    }

    private func extractKeywordGroups() -> [String] {
        // Extract common keywords from item names
        let allWords = items.flatMap { $0.name.lowercased().components(separatedBy: .whitespaces) }
        var frequency: [String: Int] = [:]
        for word in allWords where word.count >= 3 {
            frequency[word, default: 0] += 1
        }
        // Return words that appear 2+ times, sorted by frequency
        return frequency
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .map(\.key)
    }

    /// Items grouped by autoGroup value
    func groupedItems(for category: ItemCategory) -> [(group: String?, items: [DeclutterItem])] {
        let catItems = items(for: category)
        if !isAutogrouped {
            return [(nil, catItems)]
        }
        let grouped = Dictionary(grouping: catItems) { $0.autoGroup }
        var result: [(String?, [DeclutterItem])] = []
        // Named groups first, then ungrouped
        for (key, value) in grouped.sorted(by: { ($0.key ?? "zzz") < ($1.key ?? "zzz") }) {
            result.append((key, value))
        }
        return result
    }

    // MARK: - Computed Properties

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
