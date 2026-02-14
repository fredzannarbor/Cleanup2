import SwiftUI

struct DeclutterTabView: View {
    @EnvironmentObject var roomManager: RoomManager
    @State private var showAddRoom = false
    @State private var showShareReport = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if roomManager.rooms.isEmpty {
                    EmptyStateView(
                        icon: "house.fill",
                        title: "No Rooms Yet",
                        message: "Add rooms to start decluttering your home.",
                        actionLabel: "Add Room",
                        action: { showAddRoom = true }
                    )
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(roomManager.rooms) { room in
                            NavigationLink(value: room.id) {
                                RoomCardView(room: room)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Declutter")
            .navigationDestination(for: Int64.self) { roomId in
                RoomDetailView(roomId: roomId)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !roomManager.rooms.isEmpty {
                        Button {
                            showShareReport = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    Button {
                        showAddRoom = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddRoom) {
                AddRoomSheet(isPresented: $showAddRoom)
            }
            .sheet(isPresented: $showShareReport) {
                ShareStatusReportView(rooms: roomManager.rooms)
            }
            .onAppear {
                roomManager.loadRooms()
            }
        }
    }
}

// MARK: - Room Card

private struct RoomCardView: View {
    let room: Room

    var body: some View {
        VStack(spacing: 12) {
            RoomIconView(
                icon: room.icon,
                size: 56,
                color: room.isDecluttered ? .green : .indigo
            )

            Text(room.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            if room.isDecluttered {
                Label("Decluttered", systemImage: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else if room.itemCount > 0 {
                ProgressView(value: room.declutterProgress)
                    .tint(.indigo)
                    .padding(.horizontal, 8)

                Text("\(room.categorizedCount)/\(room.itemCount) items")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("No items yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Add Room Sheet

private struct AddRoomSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var roomManager: RoomManager
    @State private var name = ""
    @State private var selectedIcon: RoomIcon = .other

    var body: some View {
        NavigationStack {
            Form {
                TextField("Room Name", text: $name)

                Picker("Icon", selection: $selectedIcon) {
                    ForEach(RoomIcon.allCases) { icon in
                        Label(icon.label, systemImage: icon.systemImage)
                            .tag(icon)
                    }
                }
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        roomManager.addRoom(name: name.trimmingCharacters(in: .whitespaces), icon: selectedIcon)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
