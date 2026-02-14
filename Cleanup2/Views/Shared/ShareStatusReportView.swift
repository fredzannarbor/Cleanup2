import SwiftUI

struct ShareStatusReportView: View {
    let rooms: [Room]
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?

    private var allRooms: [Room] {
        rooms.isEmpty ? DatabaseService.shared.fetchAllRooms() : rooms
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                StatusReportContent(rooms: allRooms)
                    .padding()
            }
            .navigationTitle("Share Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ShareLink(item: renderedImage ?? UIImage(), preview: SharePreview("Cleanup\u{00B2} Status Report", image: Image(uiImage: renderedImage ?? UIImage()))) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .disabled(renderedImage == nil)
                }
            }
            .onAppear {
                renderImage()
            }
        }
    }

    @MainActor
    private func renderImage() {
        let content = StatusReportContent(rooms: allRooms)
        let renderer = ImageRenderer(content: content.frame(width: 390).padding())
        renderer.scale = 3.0
        renderedImage = renderer.uiImage
    }
}

// MARK: - Report Content (rendered to image for sharing)

struct StatusReportContent: View {
    let rooms: [Room]

    var body: some View {
        VStack(spacing: 0) {
            // Banner
            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)

                Text("Cleanup\u{00B2}")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Cleanup, cleanup,\neverybody do your share!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .italic()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [.indigo, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Room statuses
            VStack(spacing: 0) {
                ForEach(rooms) { room in
                    RoomStatusRow(room: room)
                    if room.id != rooms.last?.id {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .background(.white)

            // Summary footer
            SummaryFooter(rooms: rooms)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// MARK: - Room Status Row

private struct RoomStatusRow: View {
    let room: Room

    var body: some View {
        HStack(spacing: 12) {
            // Room icon
            Image(systemName: room.icon.systemImage)
                .font(.title3)
                .foregroundStyle(room.isDecluttered ? .green : .indigo)
                .frame(width: 36, height: 36)
                .background(
                    (room.isDecluttered ? Color.green : Color.indigo).opacity(0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Room info
            VStack(alignment: .leading, spacing: 2) {
                Text(room.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if room.isDecluttered {
                    HStack(spacing: 8) {
                        Label("Decluttered", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        if room.dueTodayCount > 0 {
                            Text("\(Int(room.cleanProgress * 100))% cleaned today")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                } else if room.nonFurnitureCount > 0 {
                    Text("\(Int(room.declutterProgress * 100))% decluttered")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if room.itemCount > 0 {
                    Text("\(room.categorizedCount)/\(room.itemCount) categorized")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not started")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Progress indicator
            if room.isDecluttered {
                if room.dueTodayCount > 0 {
                    MiniProgress(progress: room.cleanProgress, color: .blue)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else if room.nonFurnitureCount > 0 {
                MiniProgress(progress: room.declutterProgress, color: .indigo)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Mini Progress Ring

private struct MiniProgress: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Summary Footer

private struct SummaryFooter: View {
    let rooms: [Room]

    private var declutteredCount: Int {
        rooms.filter { $0.isDecluttered }.count
    }

    private var totalItems: Int {
        rooms.reduce(0) { $0 + $1.itemCount }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(declutteredCount)/\(rooms.count) rooms decluttered")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(totalItems) items tracked")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Cleanup\u{00B2}")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.indigo)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - UIImage ShareLink conformance

extension UIImage: @retroactive Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { image in
            image.pngData() ?? Data()
        }
    }
}
