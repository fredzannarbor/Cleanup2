import Foundation

struct Room: Identifiable {
    let id: Int64
    let name: String
    let icon: RoomIcon
    let isDecluttered: Bool
    let sortOrder: Int
    let createdAt: Date

    var itemCount: Int = 0
    var categorizedCount: Int = 0
    var nonFurnitureCount: Int = 0
    var nonFurnitureCategorizedCount: Int = 0
    var taskCount: Int = 0
    var dueTodayCount: Int = 0
    var completedTodayCount: Int = 0

    /// % decluttered = categorized non-furniture items / total non-furniture items
    var declutterProgress: Double {
        guard nonFurnitureCount > 0 else { return itemCount > 0 ? 1.0 : 0 }
        return Double(nonFurnitureCategorizedCount) / Double(nonFurnitureCount)
    }

    /// % cleaned = completed today / due today
    var cleanProgress: Double {
        guard dueTodayCount > 0 else { return 0 }
        return Double(completedTodayCount) / Double(dueTodayCount)
    }

    var allItemsCategorized: Bool {
        itemCount > 0 && categorizedCount == itemCount
    }
}
