import Foundation

struct CleaningTask: Identifiable {
    let id: Int64
    let roomId: Int64
    let name: String
    let frequency: TaskFrequency
    let isActive: Bool
    let createdAt: Date

    var roomName: String = ""
    var roomIcon: RoomIcon = .other
    var lastCompleted: Date?
    var isDueToday: Bool = false
    var currentStreak: Int = 0
}
