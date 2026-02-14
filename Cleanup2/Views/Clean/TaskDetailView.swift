import SwiftUI

struct TaskDetailView: View {
    let task: CleaningTask
    @EnvironmentObject var cleaningManager: CleaningManager
    @State private var logs: [CleaningLog] = []

    var body: some View {
        List {
            Section {
                HStack {
                    RoomIconView(icon: task.roomIcon, size: 44)
                    VStack(alignment: .leading) {
                        Text(task.name)
                            .font(.headline)
                        Text(task.roomName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(task.frequency.label)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(task.frequency.color.opacity(0.15))
                        .foregroundStyle(task.frequency.color)
                        .clipShape(Capsule())
                }
            }

            if task.isDueToday {
                Section {
                    Button {
                        cleaningManager.completeTask(taskId: task.id)
                        logs = DatabaseService.shared.fetchLogs(forTask: task.id)
                    } label: {
                        Label("Mark Complete", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }

            Section("Recent Completions") {
                if logs.isEmpty {
                    Text("No completions yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(logs) { log in
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                            Text(log.completedAt, style: .date)
                            Spacer()
                            Text(log.completedAt, style: .time)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            logs = DatabaseService.shared.fetchLogs(forTask: task.id)
        }
    }
}
