import SwiftUI

struct BulkCategorizeView: View {
    let roomId: Int64
    @Binding var isPresented: Bool
    @EnvironmentObject var declutterManager: DeclutterManager
    @EnvironmentObject var roomManager: RoomManager
    @State private var currentIndex = 0
    @State private var offset: CGSize = .zero

    private var uncategorized: [DeclutterItem] {
        declutterManager.uncategorizedItems
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if uncategorized.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "All Done!",
                        message: "Every item has been categorized."
                    )
                } else {
                    // Progress
                    let total = declutterManager.items.count
                    let done = declutterManager.categorizedItems.count
                    Text("\(done) of \(total) categorized")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ProgressView(value: Double(done), total: Double(total))
                        .tint(.indigo)
                        .padding(.horizontal, 32)

                    Spacer()

                    // Card
                    if currentIndex < uncategorized.count {
                        let item = uncategorized[currentIndex]
                        CardView(item: item, offset: $offset)
                            .highPriorityGesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        offset = gesture.translation
                                    }
                                    .onEnded { gesture in
                                        handleSwipe(gesture.translation, item: item)
                                    }
                            )
                    }

                    Spacer()

                    // Category buttons
                    HStack(spacing: 16) {
                        ForEach(ItemCategory.allCases.filter { $0 != .uncategorized }) { cat in
                            Button {
                                if currentIndex < uncategorized.count {
                                    categorize(uncategorized[currentIndex], as: cat)
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: cat.icon)
                                        .font(.title2)
                                    Text(cat.label)
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(cat.color.opacity(0.15))
                                .foregroundStyle(cat.color)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Categorize Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func handleSwipe(_ translation: CGSize, item: DeclutterItem) {
        let threshold: CGFloat = 100
        if translation.width > threshold {
            categorize(item, as: .keep)
        } else if translation.width < -threshold {
            categorize(item, as: .trash)
        } else if translation.height < -threshold {
            categorize(item, as: .donate)
        } else if translation.height > threshold {
            categorize(item, as: .sell)
        }
        withAnimation(.spring()) {
            offset = .zero
        }
    }

    private func categorize(_ item: DeclutterItem, as category: ItemCategory) {
        withAnimation {
            declutterManager.categorize(itemId: item.id, category: category, roomId: roomId)
            roomManager.loadRooms()
            currentIndex = 0 // Reset since array changes
        }
    }
}

private struct CardView: View {
    let item: DeclutterItem
    @Binding var offset: CGSize

    var body: some View {
        VStack(spacing: 16) {
            if let photoPath = item.photoPath,
               let image = PhotoStorageService.shared.loadPhoto(relativePath: photoPath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
            }

            Text(item.name)
                .font(.title2)
                .fontWeight(.semibold)

            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Swipe hints
            HStack {
                Label("Trash", systemImage: "arrow.left")
                    .font(.caption2)
                    .foregroundStyle(.red.opacity(0.6))
                Spacer()
                Label("Keep", systemImage: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.blue.opacity(0.6))
            }
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Label("Donate", systemImage: "arrow.up")
                        .font(.caption2)
                        .foregroundStyle(.green.opacity(0.6))
                    Label("Sell", systemImage: "arrow.down")
                        .font(.caption2)
                        .foregroundStyle(.orange.opacity(0.6))
                }
                Spacer()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width) / 20))
        .padding(.horizontal, 24)
    }
}
