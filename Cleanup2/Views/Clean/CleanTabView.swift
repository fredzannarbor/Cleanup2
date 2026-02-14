import SwiftUI

struct CleanTabView: View {
    @EnvironmentObject var cleaningManager: CleaningManager
    @EnvironmentObject var roomManager: RoomManager
    @State private var showAddTask = false

    var body: some View {
        NavigationStack {
            Group {
                if roomManager.declutteredRooms.isEmpty {
                    EmptyStateView(
                        icon: "sparkles",
                        title: "No Rooms Ready",
                        message: "Declutter a room first to unlock cleaning tasks. Head to the Declutter tab to get started!"
                    )
                } else if cleaningManager.dueTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("All Caught Up!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("No tasks due right now. Great job!")
                            .foregroundStyle(.secondary)

                        StreakBadgeView(streak: cleaningManager.currentStreak)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Streak header
                        Section {
                            HStack {
                                StreakBadgeView(streak: cleaningManager.currentStreak)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(cleaningManager.dueTasks.count)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.indigo)
                                    Text("tasks due")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        // Tasks grouped by room
                        ForEach(cleaningManager.tasksByRoom, id: \.roomName) { group in
                            Section(header: HStack {
                                Image(systemName: group.roomIcon.systemImage)
                                Text(group.roomName)
                            }) {
                                ForEach(group.tasks) { task in
                                    TaskRowView(task: task)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Clean")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(roomManager.declutteredRooms.isEmpty)
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView(isPresented: $showAddTask)
            }
            .onAppear {
                roomManager.loadRooms()
                cleaningManager.loadDueTasks()
            }
        }
    }
}

// MARK: - Task Row

private struct TaskRowView: View {
    let task: CleaningTask
    @EnvironmentObject var cleaningManager: CleaningManager

    var body: some View {
        HStack {
            Button {
                cleaningManager.completeTask(taskId: task.id)
            } label: {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(.indigo)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.body)

                HStack(spacing: 8) {
                    Text(task.frequency.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.frequency.color.opacity(0.15))
                        .foregroundStyle(task.frequency.color)
                        .clipShape(Capsule())

                    if let last = task.lastCompleted {
                        Text("Last: \(last, style: .relative) ago")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
