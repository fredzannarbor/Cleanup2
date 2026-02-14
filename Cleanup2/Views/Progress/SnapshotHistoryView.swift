import SwiftUI

struct SnapshotHistoryView: View {
    let roomId: Int64
    let roomName: String
    @EnvironmentObject var snapshotManager: SnapshotManager

    private var roomSnapshots: [StateSnapshot] {
        snapshotManager.snapshots
            .filter { $0.roomId == roomId }
            .sorted { $0.snapshotDate > $1.snapshotDate }
    }

    var body: some View {
        List {
            if roomSnapshots.isEmpty {
                Section {
                    Text("No snapshots yet. Take a snapshot from the room menu to start tracking progress.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            } else {
                ForEach(roomSnapshots) { snapshot in
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(snapshot.snapshotDate, style: .date)
                                .font(.headline)
                            Text(snapshot.snapshotDate, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 16) {
                                statBadge("Total", value: snapshot.totalItems, color: .indigo)
                                statBadge("Done", value: snapshot.categorizedCount, color: .green)
                            }
                            HStack(spacing: 16) {
                                statBadge("Keep", value: snapshot.keepCount, color: .blue)
                                statBadge("Donate", value: snapshot.donateCount, color: .green)
                                statBadge("Trash", value: snapshot.trashCount, color: .red)
                                statBadge("Sell", value: snapshot.sellCount, color: .orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Deltas section
                let deltas = snapshotManager.deltas(forRoom: roomId)
                if !deltas.isEmpty {
                    Section("Changes Between Snapshots") {
                        ForEach(Array(deltas.enumerated()), id: \.offset) { _, delta in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(delta.from.snapshotDate, style: .date) \u{2192} \(delta.to.snapshotDate, style: .date)")
                                    .font(.caption.bold())
                                HStack(spacing: 12) {
                                    deltaLabel("Items", value: delta.itemsDelta)
                                    deltaLabel("Categorized", value: delta.categorizedDelta)
                                    deltaLabel("Donated", value: delta.donateDelta)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .navigationTitle("Snapshots: \(roomName)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            snapshotManager.loadSnapshots(forRoom: roomId)
        }
    }

    private func statBadge(_ label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func deltaLabel(_ label: String, value: Int) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value >= 0 ? "+\(value)" : "\(value)")
                .font(.caption.bold())
                .foregroundStyle(value > 0 ? .green : value < 0 ? .red : .secondary)
        }
    }
}
