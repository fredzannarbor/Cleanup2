import Foundation
import GRDB

// MARK: - DB Models

struct DBRoom: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var name: String
    var icon: String
    var isDecluttered: Bool
    var sortOrder: Int
    var createdAt: Date

    static let databaseTableName = "rooms"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let icon = Column(CodingKeys.icon)
        static let isDecluttered = Column(CodingKeys.isDecluttered)
        static let sortOrder = Column(CodingKeys.sortOrder)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    func toDisplayModel() -> Room {
        Room(
            id: id ?? 0,
            name: name,
            icon: RoomIcon(rawValue: icon) ?? .other,
            isDecluttered: isDecluttered,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }
}

struct DBDeclutterItem: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var roomId: Int64
    var name: String
    var category: String
    var isFurniture: Bool
    var photoPath: String?
    var notes: String?
    var createdAt: Date

    static let databaseTableName = "declutter_items"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let roomId = Column(CodingKeys.roomId)
        static let name = Column(CodingKeys.name)
        static let category = Column(CodingKeys.category)
        static let isFurniture = Column(CodingKeys.isFurniture)
        static let photoPath = Column(CodingKeys.photoPath)
        static let notes = Column(CodingKeys.notes)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    func toDisplayModel() -> DeclutterItem {
        DeclutterItem(
            id: id ?? 0,
            roomId: roomId,
            name: name,
            category: ItemCategory(rawValue: category) ?? .uncategorized,
            isFurniture: isFurniture,
            photoPath: photoPath,
            notes: notes,
            createdAt: createdAt
        )
    }
}

struct DBCleaningTask: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var roomId: Int64
    var name: String
    var frequency: String
    var isActive: Bool
    var createdAt: Date

    static let databaseTableName = "cleaning_tasks"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let roomId = Column(CodingKeys.roomId)
        static let name = Column(CodingKeys.name)
        static let frequency = Column(CodingKeys.frequency)
        static let isActive = Column(CodingKeys.isActive)
        static let createdAt = Column(CodingKeys.createdAt)
    }

    func toDisplayModel() -> CleaningTask {
        CleaningTask(
            id: id ?? 0,
            roomId: roomId,
            name: name,
            frequency: TaskFrequency(rawValue: frequency) ?? .weekly,
            isActive: isActive,
            createdAt: createdAt
        )
    }
}

struct DBCleaningLog: Codable, FetchableRecord, PersistableRecord {
    var id: Int64?
    var taskId: Int64
    var completedAt: Date

    static let databaseTableName = "cleaning_logs"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let taskId = Column(CodingKeys.taskId)
        static let completedAt = Column(CodingKeys.completedAt)
    }

    func toDisplayModel() -> CleaningLog {
        CleaningLog(
            id: id ?? 0,
            taskId: taskId,
            completedAt: completedAt
        )
    }
}

// MARK: - Database Service

class DatabaseService {
    static let shared = DatabaseService()

    private var dbQueue: DatabaseQueue?

    var databasePath: String? {
        dbQueue?.path
    }

    private init() {
        setupDatabase()
    }

    // MARK: - Setup

    private func setupDatabase() {
        do {
            let dbPath = Self.resolveDBPath()
            let directory = (dbPath as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true
            )
            dbQueue = try DatabaseQueue(path: dbPath)
            try createTables()
            try seedDefaultRoomsIfNeeded()
        } catch {
            print("DatabaseService: Failed to setup database: \(error)")
        }
    }

    private static func resolveDBPath() -> String {
        // Try App Group container first (shared access for Claude Code)
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.nimblebooks.Cleanup2"
        ) {
            return groupURL.appendingPathComponent("Cleanup2.sqlite").path
        }
        // Fallback to Application Support
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("Cleanup2")
        return dir.appendingPathComponent("Cleanup2.sqlite").path
    }

    private func createTables() throws {
        try dbQueue?.write { db in
            try db.create(table: "rooms", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("icon", .text).notNull()
                t.column("isDecluttered", .boolean).notNull().defaults(to: false)
                t.column("sortOrder", .integer).notNull().defaults(to: 0)
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "declutter_items", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("roomId", .integer).notNull()
                    .references("rooms", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("category", .text).notNull().defaults(to: "uncategorized")
                t.column("isFurniture", .boolean).notNull().defaults(to: false)
                t.column("photoPath", .text)
                t.column("notes", .text)
                t.column("createdAt", .datetime).notNull()
            }

            // Migration: add isFurniture column if missing
            if try db.columns(in: "declutter_items").first(where: { $0.name == "isFurniture" }) == nil {
                try db.alter(table: "declutter_items") { t in
                    t.add(column: "isFurniture", .boolean).notNull().defaults(to: false)
                }
            }

            try db.create(table: "cleaning_tasks", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("roomId", .integer).notNull()
                    .references("rooms", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("frequency", .text).notNull()
                t.column("isActive", .boolean).notNull().defaults(to: true)
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "cleaning_logs", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("taskId", .integer).notNull()
                    .references("cleaning_tasks", onDelete: .cascade)
                t.column("completedAt", .datetime).notNull()
            }

            // Indexes
            try db.create(
                index: "idx_declutter_items_roomId",
                on: "declutter_items",
                columns: ["roomId"],
                ifNotExists: true
            )
            try db.create(
                index: "idx_cleaning_tasks_roomId",
                on: "cleaning_tasks",
                columns: ["roomId"],
                ifNotExists: true
            )
            try db.create(
                index: "idx_cleaning_logs_taskId",
                on: "cleaning_logs",
                columns: ["taskId"],
                ifNotExists: true
            )
            try db.create(
                index: "idx_cleaning_logs_completedAt",
                on: "cleaning_logs",
                columns: ["completedAt"],
                ifNotExists: true
            )
        }
    }

    private func seedDefaultRoomsIfNeeded() throws {
        let count = try dbQueue?.read { db in
            try DBRoom.fetchCount(db)
        } ?? 0

        guard count == 0 else { return }

        let defaultRooms: [(String, RoomIcon)] = [
            ("Kitchen", .kitchen),
            ("Living Room", .livingRoom),
            ("Master Bedroom", .bedroom),
            ("Bathroom", .bathroom),
            ("Home Office", .office),
            ("Garage", .garage),
            ("Dining Room", .diningRoom),
            ("Laundry Room", .laundry)
        ]

        try dbQueue?.write { db in
            for (index, room) in defaultRooms.enumerated() {
                var dbRoom = DBRoom(
                    id: nil,
                    name: room.0,
                    icon: room.1.rawValue,
                    isDecluttered: false,
                    sortOrder: index,
                    createdAt: Date()
                )
                try dbRoom.insert(db)
            }
        }
    }

    // MARK: - Room CRUD

    func fetchAllRooms() -> [Room] {
        do {
            let dbRooms = try dbQueue?.read { db in
                try DBRoom.order(DBRoom.Columns.sortOrder).fetchAll(db)
            } ?? []
            return dbRooms.map { dbRoom in
                var room = dbRoom.toDisplayModel()
                // Enrich with counts
                if let id = dbRoom.id {
                    room.itemCount = countItems(forRoom: id)
                    room.categorizedCount = countCategorizedItems(forRoom: id)
                    room.nonFurnitureCount = countNonFurnitureItems(forRoom: id)
                    room.nonFurnitureCategorizedCount = countCategorizedNonFurnitureItems(forRoom: id)
                    room.taskCount = countActiveTasks(forRoom: id)
                    room.dueTodayCount = countDueToday(forRoom: id)
                    room.completedTodayCount = countCompletedToday(forRoom: id)
                }
                return room
            }
        } catch {
            print("DatabaseService: Failed to fetch rooms: \(error)")
            return []
        }
    }

    func fetchRoom(id: Int64) -> Room? {
        do {
            guard let dbRoom = try dbQueue?.read({ db in
                try DBRoom.fetchOne(db, key: id)
            }) else { return nil }
            var room = dbRoom.toDisplayModel()
            room.itemCount = countItems(forRoom: id)
            room.categorizedCount = countCategorizedItems(forRoom: id)
            room.nonFurnitureCount = countNonFurnitureItems(forRoom: id)
            room.nonFurnitureCategorizedCount = countCategorizedNonFurnitureItems(forRoom: id)
            room.taskCount = countActiveTasks(forRoom: id)
            room.dueTodayCount = countDueToday(forRoom: id)
            room.completedTodayCount = countCompletedToday(forRoom: id)
            return room
        } catch {
            print("DatabaseService: Failed to fetch room: \(error)")
            return nil
        }
    }

    func insertRoom(name: String, icon: RoomIcon) -> Int64? {
        do {
            let maxOrder = try dbQueue?.read { db in
                try Int.fetchOne(db, sql: "SELECT MAX(sortOrder) FROM rooms")
            } ?? 0
            var dbRoom = DBRoom(
                id: nil,
                name: name,
                icon: icon.rawValue,
                isDecluttered: false,
                sortOrder: (maxOrder ?? 0) + 1,
                createdAt: Date()
            )
            try dbQueue?.write { db in
                try dbRoom.insert(db)
            }
            return dbRoom.id
        } catch {
            print("DatabaseService: Failed to insert room: \(error)")
            return nil
        }
    }

    func updateRoom(id: Int64, name: String? = nil, icon: RoomIcon? = nil, isDecluttered: Bool? = nil) {
        do {
            try dbQueue?.write { db in
                guard var room = try DBRoom.fetchOne(db, key: id) else { return }
                if let name = name { room.name = name }
                if let icon = icon { room.icon = icon.rawValue }
                if let isDecluttered = isDecluttered { room.isDecluttered = isDecluttered }
                try room.update(db)
            }
        } catch {
            print("DatabaseService: Failed to update room: \(error)")
        }
    }

    func deleteRoom(id: Int64) {
        do {
            try dbQueue?.write { db in
                _ = try DBRoom.deleteOne(db, key: id)
            }
        } catch {
            print("DatabaseService: Failed to delete room: \(error)")
        }
    }

    func markRoomDecluttered(id: Int64) {
        do {
            try dbQueue?.write { db in
                guard var room = try DBRoom.fetchOne(db, key: id) else { return }
                room.isDecluttered = true
                try room.update(db)
            }
            // Seed default cleaning tasks for this room
            if let room = fetchRoom(id: id) {
                seedCleaningTasks(forRoom: id, icon: room.icon)
            }
        } catch {
            print("DatabaseService: Failed to mark room decluttered: \(error)")
        }
    }

    // MARK: - Declutter Item CRUD

    func fetchItems(forRoom roomId: Int64) -> [DeclutterItem] {
        do {
            let items = try dbQueue?.read { db in
                try DBDeclutterItem
                    .filter(DBDeclutterItem.Columns.roomId == roomId)
                    .order(DBDeclutterItem.Columns.createdAt.desc)
                    .fetchAll(db)
            } ?? []
            return items.map { $0.toDisplayModel() }
        } catch {
            print("DatabaseService: Failed to fetch items: \(error)")
            return []
        }
    }

    func insertItem(roomId: Int64, name: String, category: ItemCategory = .uncategorized, isFurniture: Bool = false, photoPath: String? = nil, notes: String? = nil) -> Int64? {
        do {
            var item = DBDeclutterItem(
                id: nil,
                roomId: roomId,
                name: name,
                category: category.rawValue,
                isFurniture: isFurniture,
                photoPath: photoPath,
                notes: notes,
                createdAt: Date()
            )
            try dbQueue?.write { db in
                try item.insert(db)
            }
            return item.id
        } catch {
            print("DatabaseService: Failed to insert item: \(error)")
            return nil
        }
    }

    func insertItems(roomId: Int64, names: [String]) {
        do {
            try dbQueue?.write { db in
                for name in names {
                    var item = DBDeclutterItem(
                        id: nil,
                        roomId: roomId,
                        name: name,
                        category: ItemCategory.uncategorized.rawValue,
                        isFurniture: false,
                        photoPath: nil,
                        notes: nil,
                        createdAt: Date()
                    )
                    try item.insert(db)
                }
            }
        } catch {
            print("DatabaseService: Failed to bulk insert items: \(error)")
        }
    }

    func updateItemCategory(id: Int64, category: ItemCategory) {
        do {
            try dbQueue?.write { db in
                guard var item = try DBDeclutterItem.fetchOne(db, key: id) else { return }
                item.category = category.rawValue
                try item.update(db)
            }
        } catch {
            print("DatabaseService: Failed to update item category: \(error)")
        }
    }

    func updateItem(id: Int64, name: String? = nil, category: ItemCategory? = nil, photoPath: String? = nil, notes: String? = nil) {
        do {
            try dbQueue?.write { db in
                guard var item = try DBDeclutterItem.fetchOne(db, key: id) else { return }
                if let name = name { item.name = name }
                if let category = category { item.category = category.rawValue }
                if let photoPath = photoPath { item.photoPath = photoPath }
                if let notes = notes { item.notes = notes }
                try item.update(db)
            }
        } catch {
            print("DatabaseService: Failed to update item: \(error)")
        }
    }

    func updateItemFurniture(id: Int64, isFurniture: Bool) {
        do {
            try dbQueue?.write { db in
                guard var item = try DBDeclutterItem.fetchOne(db, key: id) else { return }
                item.isFurniture = isFurniture
                try item.update(db)
            }
        } catch {
            print("DatabaseService: Failed to update item furniture flag: \(error)")
        }
    }

    func deleteItem(id: Int64) {
        do {
            try dbQueue?.write { db in
                _ = try DBDeclutterItem.deleteOne(db, key: id)
            }
        } catch {
            print("DatabaseService: Failed to delete item: \(error)")
        }
    }

    // MARK: - Cleaning Task CRUD

    func fetchTasks(forRoom roomId: Int64) -> [CleaningTask] {
        do {
            let tasks = try dbQueue?.read { db in
                try DBCleaningTask
                    .filter(DBCleaningTask.Columns.roomId == roomId)
                    .filter(DBCleaningTask.Columns.isActive == true)
                    .order(DBCleaningTask.Columns.name)
                    .fetchAll(db)
            } ?? []
            return tasks.map { enrichTask($0.toDisplayModel()) }
        } catch {
            print("DatabaseService: Failed to fetch tasks: \(error)")
            return []
        }
    }

    func fetchAllActiveTasks() -> [CleaningTask] {
        do {
            let rows = try dbQueue?.read { db in
                try Row.fetchAll(db, sql: """
                    SELECT t.*, r.name AS roomName, r.icon AS roomIcon
                    FROM cleaning_tasks t
                    JOIN rooms r ON t.roomId = r.id
                    WHERE t.isActive = 1 AND r.isDecluttered = 1
                    ORDER BY r.sortOrder, t.name
                    """)
            } ?? []
            return rows.map { row in
                var task = CleaningTask(
                    id: row["id"],
                    roomId: row["roomId"],
                    name: row["name"],
                    frequency: TaskFrequency(rawValue: row["frequency"]) ?? .weekly,
                    isActive: row["isActive"],
                    createdAt: row["createdAt"]
                )
                task.roomName = row["roomName"]
                task.roomIcon = RoomIcon(rawValue: row["roomIcon"] ?? "") ?? .other
                return enrichTask(task)
            }
        } catch {
            print("DatabaseService: Failed to fetch all tasks: \(error)")
            return []
        }
    }

    func fetchDueTasks() -> [CleaningTask] {
        fetchAllActiveTasks().filter { $0.isDueToday }
    }

    func insertTask(roomId: Int64, name: String, frequency: TaskFrequency) -> Int64? {
        do {
            var task = DBCleaningTask(
                id: nil,
                roomId: roomId,
                name: name,
                frequency: frequency.rawValue,
                isActive: true,
                createdAt: Date()
            )
            try dbQueue?.write { db in
                try task.insert(db)
            }
            return task.id
        } catch {
            print("DatabaseService: Failed to insert task: \(error)")
            return nil
        }
    }

    func updateTask(id: Int64, name: String? = nil, frequency: TaskFrequency? = nil, isActive: Bool? = nil) {
        do {
            try dbQueue?.write { db in
                guard var task = try DBCleaningTask.fetchOne(db, key: id) else { return }
                if let name = name { task.name = name }
                if let frequency = frequency { task.frequency = frequency.rawValue }
                if let isActive = isActive { task.isActive = isActive }
                try task.update(db)
            }
        } catch {
            print("DatabaseService: Failed to update task: \(error)")
        }
    }

    func deleteTask(id: Int64) {
        do {
            try dbQueue?.write { db in
                _ = try DBCleaningTask.deleteOne(db, key: id)
            }
        } catch {
            print("DatabaseService: Failed to delete task: \(error)")
        }
    }

    // MARK: - Cleaning Log

    func completeTask(taskId: Int64) {
        do {
            var log = DBCleaningLog(
                id: nil,
                taskId: taskId,
                completedAt: Date()
            )
            try dbQueue?.write { db in
                try log.insert(db)
            }
        } catch {
            print("DatabaseService: Failed to log task completion: \(error)")
        }
    }

    func fetchLogs(forTask taskId: Int64, limit: Int = 30) -> [CleaningLog] {
        do {
            let logs = try dbQueue?.read { db in
                try DBCleaningLog
                    .filter(DBCleaningLog.Columns.taskId == taskId)
                    .order(DBCleaningLog.Columns.completedAt.desc)
                    .limit(limit)
                    .fetchAll(db)
            } ?? []
            return logs.map { $0.toDisplayModel() }
        } catch {
            print("DatabaseService: Failed to fetch logs: \(error)")
            return []
        }
    }

    func fetchAllLogs(since date: Date) -> [CleaningLog] {
        do {
            let logs = try dbQueue?.read { db in
                try DBCleaningLog
                    .filter(DBCleaningLog.Columns.completedAt >= date)
                    .order(DBCleaningLog.Columns.completedAt.desc)
                    .fetchAll(db)
            } ?? []
            return logs.map { $0.toDisplayModel() }
        } catch {
            print("DatabaseService: Failed to fetch all logs: \(error)")
            return []
        }
    }

    func lastCompletion(forTask taskId: Int64) -> Date? {
        do {
            return try dbQueue?.read { db in
                try DBCleaningLog
                    .filter(DBCleaningLog.Columns.taskId == taskId)
                    .order(DBCleaningLog.Columns.completedAt.desc)
                    .fetchOne(db)
            }?.completedAt
        } catch {
            print("DatabaseService: Failed to get last completion: \(error)")
            return nil
        }
    }

    // MARK: - Aggregates

    func countItems(forRoom roomId: Int64) -> Int {
        (try? dbQueue?.read { db in
            try DBDeclutterItem
                .filter(DBDeclutterItem.Columns.roomId == roomId)
                .fetchCount(db)
        }) ?? 0
    }

    func countCategorizedItems(forRoom roomId: Int64) -> Int {
        (try? dbQueue?.read { db in
            try DBDeclutterItem
                .filter(DBDeclutterItem.Columns.roomId == roomId)
                .filter(DBDeclutterItem.Columns.category != ItemCategory.uncategorized.rawValue)
                .fetchCount(db)
        }) ?? 0
    }

    func countNonFurnitureItems(forRoom roomId: Int64) -> Int {
        (try? dbQueue?.read { db in
            try DBDeclutterItem
                .filter(DBDeclutterItem.Columns.roomId == roomId)
                .filter(DBDeclutterItem.Columns.isFurniture == false)
                .fetchCount(db)
        }) ?? 0
    }

    func countCategorizedNonFurnitureItems(forRoom roomId: Int64) -> Int {
        (try? dbQueue?.read { db in
            try DBDeclutterItem
                .filter(DBDeclutterItem.Columns.roomId == roomId)
                .filter(DBDeclutterItem.Columns.isFurniture == false)
                .filter(DBDeclutterItem.Columns.category != ItemCategory.uncategorized.rawValue)
                .fetchCount(db)
        }) ?? 0
    }

    func countDueToday(forRoom roomId: Int64) -> Int {
        let tasks = fetchTasks(forRoom: roomId)
        return tasks.filter { $0.isDueToday }.count
    }

    func countActiveTasks(forRoom roomId: Int64) -> Int {
        (try? dbQueue?.read { db in
            try DBCleaningTask
                .filter(DBCleaningTask.Columns.roomId == roomId)
                .filter(DBCleaningTask.Columns.isActive == true)
                .fetchCount(db)
        }) ?? 0
    }

    func countCompletedToday(forRoom roomId: Int64) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return (try? dbQueue?.read { db in
            try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM cleaning_logs cl
                JOIN cleaning_tasks ct ON cl.taskId = ct.id
                WHERE ct.roomId = ? AND cl.completedAt >= ?
                """, arguments: [roomId, startOfDay])
        }) ?? 0
    }

    func countItemsByCategory() -> [ItemCategory: Int] {
        var result: [ItemCategory: Int] = [:]
        do {
            let rows = try dbQueue?.read { db in
                try Row.fetchAll(db, sql: """
                    SELECT category, COUNT(*) as cnt FROM declutter_items GROUP BY category
                    """)
            } ?? []
            for row in rows {
                if let cat = ItemCategory(rawValue: row["category"]) {
                    result[cat] = row["cnt"]
                }
            }
        } catch {
            print("DatabaseService: Failed to count by category: \(error)")
        }
        return result
    }

    func totalItemCount() -> Int {
        (try? dbQueue?.read { db in
            try DBDeclutterItem.fetchCount(db)
        }) ?? 0
    }

    func declutteredRoomCount() -> Int {
        (try? dbQueue?.read { db in
            try DBRoom.filter(DBRoom.Columns.isDecluttered == true).fetchCount(db)
        }) ?? 0
    }

    func totalRoomCount() -> Int {
        (try? dbQueue?.read { db in
            try DBRoom.fetchCount(db)
        }) ?? 0
    }

    // MARK: - Streak Calculation

    func currentCleaningStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Check if today has completions; if not start from yesterday
        let todayCount = completionCount(on: checkDate)
        if todayCount == 0 {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        while true {
            let count = completionCount(on: checkDate)
            if count > 0 {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    func longestCleaningStreak() -> Int {
        // Get all unique completion dates
        do {
            let dates: [Date] = try dbQueue?.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT DISTINCT date(completedAt) as day FROM cleaning_logs ORDER BY day
                    """)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return rows.compactMap { row -> Date? in
                    guard let dayStr: String = row["day"] else { return nil }
                    return formatter.date(from: dayStr)
                }
            } ?? []

            guard !dates.isEmpty else { return 0 }

            let calendar = Calendar.current
            var longest = 1
            var current = 1
            for i in 1..<dates.count {
                let diff = calendar.dateComponents([.day], from: dates[i-1], to: dates[i]).day ?? 0
                if diff == 1 {
                    current += 1
                    longest = max(longest, current)
                } else {
                    current = 1
                }
            }
            return longest
        } catch {
            print("DatabaseService: Failed to compute longest streak: \(error)")
            return 0
        }
    }

    func completionCount(on date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return (try? dbQueue?.read { db in
            try DBCleaningLog
                .filter(DBCleaningLog.Columns.completedAt >= start)
                .filter(DBCleaningLog.Columns.completedAt < end)
                .fetchCount(db)
        }) ?? 0
    }

    /// Returns completion counts per day for the last N days
    func dailyCompletionCounts(days: Int) -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: Date()))!
        do {
            let rows = try dbQueue?.read { db in
                try Row.fetchAll(db, sql: """
                    SELECT date(completedAt) as day, COUNT(*) as cnt
                    FROM cleaning_logs
                    WHERE completedAt >= ?
                    GROUP BY date(completedAt)
                    ORDER BY day
                    """, arguments: [startDate])
            } ?? []
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return rows.compactMap { row -> (Date, Int)? in
                guard let dayStr: String = row["day"],
                      let date = formatter.date(from: dayStr),
                      let count: Int = row["cnt"] else { return nil }
                return (date, count)
            }
        } catch {
            print("DatabaseService: Failed to get daily counts: \(error)")
            return []
        }
    }

    // MARK: - Helpers

    private func seedCleaningTasks(forRoom roomId: Int64, icon: RoomIcon) {
        do {
            try dbQueue?.write { db in
                for taskDef in icon.defaultCleaningTasks {
                    var task = DBCleaningTask(
                        id: nil,
                        roomId: roomId,
                        name: taskDef.name,
                        frequency: taskDef.frequency.rawValue,
                        isActive: true,
                        createdAt: Date()
                    )
                    try task.insert(db)
                }
            }
        } catch {
            print("DatabaseService: Failed to seed cleaning tasks: \(error)")
        }
    }

    private func enrichTask(_ task: CleaningTask) -> CleaningTask {
        var enriched = task
        enriched.lastCompleted = lastCompletion(forTask: task.id)

        // Determine if due today
        if let last = enriched.lastCompleted {
            let calendar = Calendar.current
            switch task.frequency {
            case .daily:
                enriched.isDueToday = !calendar.isDateInToday(last)
            case .weekly:
                let daysSince = calendar.dateComponents([.day], from: last, to: Date()).day ?? 0
                enriched.isDueToday = daysSince >= 7
            case .monthly:
                let daysSince = calendar.dateComponents([.day], from: last, to: Date()).day ?? 0
                enriched.isDueToday = daysSince >= 30
            }
        } else {
            // Never completed = due today
            enriched.isDueToday = true
        }

        // If room info not yet set, look it up
        if enriched.roomName.isEmpty {
            if let room = fetchRoom(id: task.roomId) {
                enriched.roomName = room.name
                enriched.roomIcon = room.icon
            }
        }

        return enriched
    }
}
