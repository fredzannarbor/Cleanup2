import Foundation

@MainActor
class CleaningManager: ObservableObject {
    @Published var dueTasks: [CleaningTask] = []
    @Published var allTasks: [CleaningTask] = []
    @Published var currentStreak: Int = 0
    @Published var isLoading = false

    private let db = DatabaseService.shared

    func loadDueTasks() {
        isLoading = true
        dueTasks = db.fetchDueTasks()
        allTasks = db.fetchAllActiveTasks()
        currentStreak = db.currentCleaningStreak()
        isLoading = false
    }

    func loadTasks(forRoom roomId: Int64) {
        allTasks = db.fetchTasks(forRoom: roomId)
    }

    func completeTask(taskId: Int64) {
        db.completeTask(taskId: taskId)
        loadDueTasks()
    }

    func addTask(roomId: Int64, name: String, frequency: TaskFrequency) {
        _ = db.insertTask(roomId: roomId, name: name, frequency: frequency)
        loadDueTasks()
    }

    func updateTask(id: Int64, name: String? = nil, frequency: TaskFrequency? = nil, isActive: Bool? = nil) {
        db.updateTask(id: id, name: name, frequency: frequency, isActive: isActive)
        loadDueTasks()
    }

    func deleteTask(id: Int64) {
        db.deleteTask(id: id)
        loadDueTasks()
    }

    /// Tasks grouped by room name
    var tasksByRoom: [(roomName: String, roomIcon: RoomIcon, tasks: [CleaningTask])] {
        let grouped = Dictionary(grouping: dueTasks) { $0.roomName }
        return grouped.map { key, tasks in
            (roomName: key, roomIcon: tasks.first?.roomIcon ?? .other, tasks: tasks)
        }.sorted { $0.roomName < $1.roomName }
    }

    var completedTodayCount: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return db.fetchAllLogs(since: startOfDay).count
    }
}
