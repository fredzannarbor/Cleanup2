import SwiftUI
import Charts

struct ProgressTabView: View {
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var roomManager: RoomManager
    @EnvironmentObject var subscriptionService: SubscriptionService
    @EnvironmentObject var snapshotManager: SnapshotManager
    @State private var showPaywall = false

    private var isPremium: Bool {
        subscriptionService.effectivelyPremium
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let summary = progressManager.summary {
                    VStack(spacing: 16) {
                        // Stats cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatsCardView(
                                title: "Items Processed",
                                value: "\(summary.categorizedCount)",
                                icon: "archivebox.fill",
                                color: .indigo
                            )
                            StatsCardView(
                                title: "Donated",
                                value: "\(summary.donateCount)",
                                icon: "heart.fill",
                                color: .green
                            )
                            StatsCardView(
                                title: "Sold",
                                value: "\(summary.sellCount)",
                                icon: "dollarsign.circle.fill",
                                color: .orange
                            )
                            StatsCardView(
                                title: "Streak",
                                value: "\(summary.currentStreak)d",
                                icon: "flame.fill",
                                color: .orange
                            )
                        }

                        // Rooms progress
                        HStack {
                            Text("Rooms Decluttered")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(summary.roomsDecluttered) / \(summary.totalRooms)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 4)

                        // Room bar chart
                        if !roomManager.rooms.isEmpty {
                            DeclutterProgressChart(rooms: roomManager.rooms)
                        }

                        // Category pie chart
                        if summary.categorizedCount > 0 {
                            CategoryPieChart(summary: summary)
                        }

                        // Cleaning activity heatmap
                        StreakCalendarView(dailyCounts: progressManager.dailyCounts)

                        // Premium sections
                        Divider()
                            .padding(.vertical, 4)

                        // Snapshot History
                        premiumSection(
                            title: "Snapshot History",
                            icon: "clock.arrow.circlepath",
                            description: "Track your progress over time"
                        ) {
                            if snapshotManager.snapshots.isEmpty {
                                Text("No snapshots yet. Take snapshots from room detail views.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(snapshotManager.snapshots.prefix(3)) { snapshot in
                                    if let room = roomManager.rooms.first(where: { $0.id == snapshot.roomId }) {
                                        NavigationLink {
                                            SnapshotHistoryView(roomId: snapshot.roomId, roomName: room.name)
                                        } label: {
                                            HStack {
                                                RoomIconView(icon: room.icon, size: 28, color: .indigo)
                                                VStack(alignment: .leading) {
                                                    Text(room.name)
                                                        .font(.subheadline)
                                                    Text(snapshot.snapshotDate, style: .date)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                Text("\(snapshot.totalItems) items")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Recommendations
                        premiumSection(
                            title: "Recommendations",
                            icon: "chart.bar.xaxis",
                            description: "Smart suggestions for where to focus"
                        ) {
                            NavigationLink {
                                RecommendationsView()
                            } label: {
                                Label("View Recommendations", systemImage: "arrow.right")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Progress")
            .onAppear {
                progressManager.loadStats()
                roomManager.loadRooms()
                snapshotManager.loadAllSnapshots()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    @ViewBuilder
    private func premiumSection<Content: View>(title: String, icon: String, description: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.indigo)
                Text(title)
                    .font(.headline)
                Spacer()
                if !isPremium {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if isPremium {
                content()
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Unlock")
                            .font(.caption.bold())
                            .foregroundStyle(.indigo)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Category Pie Chart

private struct CategoryPieChart: View {
    let summary: DeclutterSummary

    private var data: [(category: String, count: Int, color: Color)] {
        [
            ("Keep", summary.keepCount, .blue),
            ("Donate", summary.donateCount, .green),
            ("Trash", summary.trashCount, .red),
            ("Sell", summary.sellCount, .orange)
        ].filter { $0.count > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Item Categories")
                .font(.headline)

            Chart(data, id: \.category) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
            }
            .frame(height: 200)

            // Legend
            HStack(spacing: 16) {
                ForEach(data, id: \.category) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        Text("\(item.category): \(item.count)")
                            .font(.caption)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
