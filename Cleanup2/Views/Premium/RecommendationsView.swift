import SwiftUI

struct RoomRecommendation: Identifiable {
    let id: Int64
    let roomName: String
    let roomIcon: RoomIcon
    let reason: String
    let priority: Int // 1 = highest
    let uncategorizedCount: Int
    let totalItems: Int
}

struct RecommendationsView: View {
    @EnvironmentObject var roomManager: RoomManager

    private var recommendations: [RoomRecommendation] {
        var recs: [RoomRecommendation] = []

        for room in roomManager.rooms where !room.isDecluttered {
            let uncategorized = room.itemCount - room.categorizedCount
            var priority = 0
            var reason = ""

            if uncategorized > 20 {
                priority = 1
                reason = "High volume: \(uncategorized) uncategorized items. Tackling this room will make a big impact."
            } else if uncategorized > 10 {
                priority = 2
                reason = "\(uncategorized) items need categorizing. A focused session could clear this room."
            } else if room.itemCount > 0 && room.categorizedCount == 0 {
                priority = 3
                reason = "Not started yet. \(room.itemCount) items waiting — even 10 minutes helps."
            } else if uncategorized > 0 {
                priority = 4
                reason = "Almost done! Just \(uncategorized) items left to categorize."
            } else if room.itemCount == 0 {
                priority = 5
                reason = "Empty room. Add items to start decluttering."
            }

            if priority > 0 {
                recs.append(RoomRecommendation(
                    id: room.id,
                    roomName: room.name,
                    roomIcon: room.icon,
                    reason: reason,
                    priority: priority,
                    uncategorizedCount: uncategorized,
                    totalItems: room.itemCount
                ))
            }
        }

        return recs.sorted { $0.priority < $1.priority }
    }

    var body: some View {
        List {
            if recommendations.isEmpty {
                Section {
                    Text("All rooms are decluttered. Great work!")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Where to Focus Next") {
                    ForEach(recommendations) { rec in
                        HStack(spacing: 12) {
                            RoomIconView(icon: rec.roomIcon, size: 36, color: priorityColor(rec.priority))
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(rec.roomName)
                                        .font(.headline)
                                    if rec.priority == 1 {
                                        Text("TOP PRIORITY")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.red.opacity(0.15))
                                            .foregroundStyle(.red)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(rec.reason)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Summary stats
                Section("Overview") {
                    let totalUncategorized = recommendations.reduce(0) { $0 + $1.uncategorizedCount }
                    let totalItems = recommendations.reduce(0) { $0 + $1.totalItems }
                    let roomsLeft = recommendations.count

                    HStack {
                        Text("Rooms remaining")
                        Spacer()
                        Text("\(roomsLeft)")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Items to categorize")
                        Spacer()
                        Text("\(totalUncategorized)")
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Total items across rooms")
                        Spacer()
                        Text("\(totalItems)")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationTitle("Recommendations")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        default: return .gray
        }
    }
}
