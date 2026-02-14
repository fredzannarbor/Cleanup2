import Foundation

struct DeclutterSummary {
    let totalItems: Int
    let keepCount: Int
    let donateCount: Int
    let trashCount: Int
    let sellCount: Int
    let uncategorizedCount: Int
    let roomsDecluttered: Int
    let totalRooms: Int
    let currentStreak: Int
    let longestStreak: Int

    var categorizedCount: Int {
        keepCount + donateCount + trashCount + sellCount
    }

    var progress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(categorizedCount) / Double(totalItems)
    }
}
