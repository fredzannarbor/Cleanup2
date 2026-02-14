import Foundation

@MainActor
class RoomManager: ObservableObject {
    @Published var rooms: [Room] = []
    @Published var isLoading = false

    private let db = DatabaseService.shared

    func loadRooms() {
        isLoading = true
        rooms = db.fetchAllRooms()
        isLoading = false
    }

    func addRoom(name: String, icon: RoomIcon) {
        _ = db.insertRoom(name: name, icon: icon)
        loadRooms()
    }

    func updateRoom(id: Int64, name: String? = nil, icon: RoomIcon? = nil) {
        db.updateRoom(id: id, name: name, icon: icon)
        loadRooms()
    }

    func deleteRoom(id: Int64) {
        db.deleteRoom(id: id)
        loadRooms()
    }

    func markDecluttered(id: Int64) {
        db.markRoomDecluttered(id: id)
        loadRooms()
    }

    var declutteredRooms: [Room] {
        rooms.filter { $0.isDecluttered }
    }

    var undeclutteredRooms: [Room] {
        rooms.filter { !$0.isDecluttered }
    }
}
