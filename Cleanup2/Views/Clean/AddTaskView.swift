import SwiftUI

struct AddTaskView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var cleaningManager: CleaningManager
    @EnvironmentObject var roomManager: RoomManager

    @State private var name = ""
    @State private var frequency: TaskFrequency = .weekly
    @State private var selectedRoomId: Int64?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task Name", text: $name)

                Picker("Room", selection: $selectedRoomId) {
                    Text("Select a room").tag(nil as Int64?)
                    ForEach(roomManager.declutteredRooms) { room in
                        Label(room.name, systemImage: room.icon.systemImage)
                            .tag(room.id as Int64?)
                    }
                }

                Picker("Frequency", selection: $frequency) {
                    ForEach(TaskFrequency.allCases) { freq in
                        Text(freq.label).tag(freq)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let roomId = selectedRoomId,
                              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        cleaningManager.addTask(roomId: roomId, name: name.trimmingCharacters(in: .whitespaces), frequency: frequency)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedRoomId == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
