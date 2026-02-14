import Foundation

struct StateSnapshot: Identifiable {
    let id: Int64
    let snapshotDate: Date
    let roomId: Int64
    let totalItems: Int
    let categorizedCount: Int
    let keepCount: Int
    let donateCount: Int
    let trashCount: Int
    let sellCount: Int
    let furnitureCount: Int
    let createdAt: Date
}

struct SnapshotDelta {
    let from: StateSnapshot
    let to: StateSnapshot
    let itemsDelta: Int
    let categorizedDelta: Int
    let keepDelta: Int
    let donateDelta: Int
    let trashDelta: Int
    let sellDelta: Int
}

@MainActor
class SnapshotManager: ObservableObject {
    @Published var snapshots: [StateSnapshot] = []
    @Published var isLoading = false

    private let db = DatabaseService.shared

    func takeSnapshot(roomId: Int64, items: [DeclutterItem]) {
        _ = db.insertSnapshot(roomId: roomId, items: items)
        loadSnapshots(forRoom: roomId)
    }

    func loadSnapshots(forRoom roomId: Int64) {
        isLoading = true
        let dbSnapshots = db.fetchSnapshots(forRoom: roomId)
        snapshots = dbSnapshots.map { s in
            StateSnapshot(
                id: s.id ?? 0,
                snapshotDate: s.snapshotDate,
                roomId: s.roomId,
                totalItems: s.totalItems,
                categorizedCount: s.categorizedCount,
                keepCount: s.keepCount,
                donateCount: s.donateCount,
                trashCount: s.trashCount,
                sellCount: s.sellCount,
                furnitureCount: s.furnitureCount,
                createdAt: s.createdAt
            )
        }
        isLoading = false
    }

    func loadAllSnapshots() {
        isLoading = true
        let dbSnapshots = db.fetchAllSnapshots()
        snapshots = dbSnapshots.map { s in
            StateSnapshot(
                id: s.id ?? 0,
                snapshotDate: s.snapshotDate,
                roomId: s.roomId,
                totalItems: s.totalItems,
                categorizedCount: s.categorizedCount,
                keepCount: s.keepCount,
                donateCount: s.donateCount,
                trashCount: s.trashCount,
                sellCount: s.sellCount,
                furnitureCount: s.furnitureCount,
                createdAt: s.createdAt
            )
        }
        isLoading = false
    }

    func computeDelta(from older: StateSnapshot, to newer: StateSnapshot) -> SnapshotDelta {
        SnapshotDelta(
            from: older,
            to: newer,
            itemsDelta: newer.totalItems - older.totalItems,
            categorizedDelta: newer.categorizedCount - older.categorizedCount,
            keepDelta: newer.keepCount - older.keepCount,
            donateDelta: newer.donateCount - older.donateCount,
            trashDelta: newer.trashCount - older.trashCount,
            sellDelta: newer.sellCount - older.sellCount
        )
    }

    /// Returns deltas between consecutive snapshots for a room
    func deltas(forRoom roomId: Int64) -> [SnapshotDelta] {
        let roomSnapshots = snapshots
            .filter { $0.roomId == roomId }
            .sorted { $0.snapshotDate < $1.snapshotDate }

        guard roomSnapshots.count >= 2 else { return [] }

        var result: [SnapshotDelta] = []
        for i in 1..<roomSnapshots.count {
            result.append(computeDelta(from: roomSnapshots[i-1], to: roomSnapshots[i]))
        }
        return result
    }
}
