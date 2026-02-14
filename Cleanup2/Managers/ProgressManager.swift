import Foundation

@MainActor
class ProgressManager: ObservableObject {
    @Published var summary: DeclutterSummary?
    @Published var dailyCounts: [(date: Date, count: Int)] = []
    @Published var categoryBreakdown: [ItemCategory: Int] = [:]
    @Published var isLoading = false

    private let db = DatabaseService.shared

    func loadStats() {
        isLoading = true

        let counts = db.countItemsByCategory()
        categoryBreakdown = counts

        let totalItems = db.totalItemCount()
        let declutteredRooms = db.declutteredRoomCount()
        let totalRooms = db.totalRoomCount()
        let streak = db.currentCleaningStreak()
        let longest = db.longestCleaningStreak()

        summary = DeclutterSummary(
            totalItems: totalItems,
            keepCount: counts[.keep] ?? 0,
            donateCount: counts[.donate] ?? 0,
            trashCount: counts[.trash] ?? 0,
            sellCount: counts[.sell] ?? 0,
            uncategorizedCount: counts[.uncategorized] ?? 0,
            roomsDecluttered: declutteredRooms,
            totalRooms: totalRooms,
            currentStreak: streak,
            longestStreak: longest
        )

        dailyCounts = db.dailyCompletionCounts(days: 30)

        isLoading = false
    }
}
