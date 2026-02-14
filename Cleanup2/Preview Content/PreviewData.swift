import Foundation

enum PreviewData {
    static let sampleRooms: [Room] = [
        Room(id: 1, name: "Kitchen", icon: .kitchen, isDecluttered: false, sortOrder: 0, createdAt: Date(), itemCount: 12, categorizedCount: 8, nonFurnitureCount: 10, nonFurnitureCategorizedCount: 7, taskCount: 0, dueTodayCount: 0, completedTodayCount: 0),
        Room(id: 2, name: "Living Room", icon: .livingRoom, isDecluttered: true, sortOrder: 1, createdAt: Date(), itemCount: 6, categorizedCount: 6, nonFurnitureCount: 4, nonFurnitureCategorizedCount: 4, taskCount: 3, dueTodayCount: 2, completedTodayCount: 1),
        Room(id: 3, name: "Master Bedroom", icon: .bedroom, isDecluttered: false, sortOrder: 2, createdAt: Date(), itemCount: 0, categorizedCount: 0, nonFurnitureCount: 0, nonFurnitureCategorizedCount: 0, taskCount: 0, dueTodayCount: 0, completedTodayCount: 0)
    ]

    static let sampleItems: [DeclutterItem] = [
        DeclutterItem(id: 1, roomId: 1, name: "Old blender", category: .donate, isFurniture: false, photoPath: nil, notes: "Still works, just don't use it", createdAt: Date()),
        DeclutterItem(id: 2, roomId: 1, name: "Chipped plates", category: .trash, isFurniture: false, photoPath: nil, notes: nil, createdAt: Date()),
        DeclutterItem(id: 3, roomId: 1, name: "Cast iron skillet", category: .keep, isFurniture: false, photoPath: nil, notes: "Grandmother's", createdAt: Date()),
        DeclutterItem(id: 4, roomId: 1, name: "Vintage toaster", category: .sell, isFurniture: false, photoPath: nil, notes: "Works, retro style", createdAt: Date()),
        DeclutterItem(id: 5, roomId: 1, name: "Mystery gadget", category: .uncategorized, isFurniture: false, photoPath: nil, notes: nil, createdAt: Date()),
        DeclutterItem(id: 6, roomId: 1, name: "Kitchen table", category: .keep, isFurniture: true, photoPath: nil, notes: "Staying", createdAt: Date())
    ]

    static let sampleTasks: [CleaningTask] = [
        {
            var t = CleaningTask(id: 1, roomId: 2, name: "Vacuum floor", frequency: .weekly, isActive: true, createdAt: Date())
            t.roomName = "Living Room"
            t.roomIcon = .livingRoom
            t.isDueToday = true
            return t
        }(),
        {
            var t = CleaningTask(id: 2, roomId: 2, name: "Dust surfaces", frequency: .weekly, isActive: true, createdAt: Date())
            t.roomName = "Living Room"
            t.roomIcon = .livingRoom
            t.isDueToday = true
            return t
        }()
    ]

    static let sampleSummary = DeclutterSummary(
        totalItems: 25,
        keepCount: 10,
        donateCount: 8,
        trashCount: 4,
        sellCount: 3,
        uncategorizedCount: 0,
        roomsDecluttered: 2,
        totalRooms: 8,
        currentStreak: 5,
        longestStreak: 12
    )
}
