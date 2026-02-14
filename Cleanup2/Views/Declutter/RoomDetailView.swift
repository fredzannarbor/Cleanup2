import SwiftUI
import UniformTypeIdentifiers

struct RoomDetailView: View {
    let roomId: Int64
    @EnvironmentObject var roomManager: RoomManager
    @EnvironmentObject var declutterManager: DeclutterManager
    @EnvironmentObject var subscriptionService: SubscriptionService
    @EnvironmentObject var snapshotManager: SnapshotManager
    @State private var showAddItem = false
    @State private var showBulkCategorize = false
    @State private var showScanView = false
    @State private var showDeclutterConfirm = false
    @State private var showSummary = false
    @State private var showRenameSheet = false
    @State private var showDeleteConfirm = false
    @State private var showShareReport = false
    @State private var pastedItemCount = 0
    @State private var showPasteConfirm = false
    @State private var showFileImporter = false
    @State private var importedItemCount = 0
    @State private var showImportConfirm = false
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @State private var showPaywall = false
    @State private var showScienceView = false
    @State private var showSnapshotHistory = false
    @State private var showSnapshotConfirm = false
    @StateObject private var speechService = SpeechService()
    @State private var isRecordingVoice = false
    @Environment(\.dismiss) private var dismiss

    private var room: Room? {
        roomManager.rooms.first { $0.id == roomId }
    }

    private var isPremium: Bool {
        subscriptionService.effectivelyPremium
    }

    var body: some View {
        Group {
            if let room = room {
                roomContent(room)
            } else {
                Text("Room not found")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            declutterManager.loadItems(forRoom: roomId)
        }
    }

    // MARK: - Room Content

    @ViewBuilder
    private func roomContent(_ room: Room) -> some View {
        List {
            roomStatusSection(room)
            quickActionsSection(room)
            itemSections
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showAddItem) {
            AddItemView(roomId: roomId, isPresented: $showAddItem)
        }
        .fullScreenCover(isPresented: $showBulkCategorize) {
            BulkCategorizeView(roomId: roomId, isPresented: $showBulkCategorize)
        }
        .sheet(isPresented: $showScanView) {
            RoomScanView(roomId: roomId, isPresented: $showScanView)
        }
        .sheet(isPresented: $showSummary) {
            DeclutterSummaryView(roomId: roomId, roomName: room.name)
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameRoomSheet(roomId: roomId, currentName: room.name, isPresented: $showRenameSheet)
        }
        .sheet(isPresented: $showShareReport) {
            ShareStatusReportView(rooms: [room])
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showScienceView) { scienceSheet(room) }
        .sheet(isPresented: $showSnapshotHistory) { snapshotHistorySheet(room) }
        .alert("Mark as Decluttered?", isPresented: $showDeclutterConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Declutter") {
                roomManager.markDecluttered(id: roomId)
                showSummary = true
            }
        } message: {
            Text("This will transition \(room.name) to cleaning mode with default recurring tasks.")
        }
        .alert("Snapshot Saved", isPresented: $showSnapshotConfirm) {
            Button("OK") { }
        } message: {
            Text("A snapshot of \(room.name) has been saved. View history from the menu.")
        }
        .alert("\(pastedItemCount) Items Pasted", isPresented: $showPasteConfirm) {
            Button("OK") { }
        } message: {
            Text("Added \(pastedItemCount) items from clipboard as uncategorized.")
        }
        .alert("\(importedItemCount) Items Imported", isPresented: $showImportConfirm) {
            Button("OK") { }
        } message: {
            Text("Added \(importedItemCount) items from file as uncategorized.")
        }
        .alert("Import Error", isPresented: $showImportError) {
            Button("OK") { }
        } message: {
            Text(importErrorMessage)
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.plainText, .commaSeparatedText]) { result in
            switch result {
            case .success(let url): importFromFile(url: url)
            case .failure(let error):
                importErrorMessage = error.localizedDescription
                showImportError = true
            }
        }
        .alert("Delete \(room.name)?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                roomManager.deleteRoom(id: roomId)
                dismiss()
            }
        } message: {
            Text("This will permanently remove the room and all its items and tasks.")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func roomStatusSection(_ room: Room) -> some View {
        Section {
            HStack {
                RoomIconView(icon: room.icon, size: 44, color: room.isDecluttered ? .green : .indigo)
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name).font(.headline)
                    roomStatusLabel(room)
                }
                Spacer()
                if room.nonFurnitureCount > 0 {
                    CircularProgressView(progress: room.declutterProgress)
                        .frame(width: 44, height: 44)
                }
            }
        }
    }

    @ViewBuilder
    private func roomStatusLabel(_ room: Room) -> some View {
        if room.isDecluttered {
            HStack(spacing: 12) {
                Label("Decluttered", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(.green)
                if room.dueTodayCount > 0 {
                    Text("\(Int(room.cleanProgress * 100))% cleaned")
                        .font(.caption).foregroundStyle(.blue)
                }
            }
        } else if room.nonFurnitureCount > 0 {
            Text("\(Int(room.declutterProgress * 100))% decluttered (excl. furniture)")
                .font(.caption).foregroundStyle(.secondary)
        } else if room.itemCount > 0 {
            Text("\(room.categorizedCount) of \(room.itemCount) categorized")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func quickActionsSection(_ room: Room) -> some View {
        if !room.isDecluttered {
            Section {
                Button { showBulkCategorize = true } label: {
                    Label("Bulk Categorize", systemImage: "rectangle.stack.fill")
                }
                .disabled(declutterManager.uncategorizedItems.isEmpty)

                Button { showScanView = true } label: {
                    Label("Scan Room (Video)", systemImage: "video.fill")
                }

                if room.allItemsCategorized && room.itemCount > 0 {
                    Button { showDeclutterConfirm = true } label: {
                        Label("Mark as Decluttered", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var itemSections: some View {
        ForEach(ItemCategory.allCases) { category in
            let categoryItems = declutterManager.items(for: category)
            if !categoryItems.isEmpty {
                Section(header: categoryHeader(category, count: categoryItems.count)) {
                    ForEach(categoryItems) { item in
                        ItemRowView(item: item, roomId: roomId)
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            declutterManager.deleteItem(id: categoryItems[idx].id, roomId: roomId)
                        }
                        roomManager.loadRooms()
                    }
                    .onMove(perform: isPremium ? { source, destination in
                        declutterManager.moveItems(in: category, from: source, to: destination, roomId: roomId)
                    } : nil)
                }
            }
        }
    }

    private func categoryHeader(_ category: ItemCategory, count: Int) -> some View {
        HStack {
            Image(systemName: category.icon).foregroundStyle(category.color)
            Text(category.label)
            Spacer()
            Text("\(count)").foregroundStyle(.secondary)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { toggleVoiceInput() } label: {
                Image(systemName: isRecordingVoice ? "mic.fill" : "mic")
                    .foregroundStyle(isRecordingVoice ? .red : .primary)
            }

            Button { showAddItem = true } label: {
                Image(systemName: "plus")
            }

            Menu { menuContent } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        sortMenu
        Divider()
        premiumMenuItems
        Divider()
        importMenuItems
        Divider()
        Button { showShareReport = true } label: {
            Label("Share Status", systemImage: "square.and.arrow.up")
        }
        Button { showRenameSheet = true } label: {
            Label("Rename Room", systemImage: "pencil")
        }
        Divider()
        Button(role: .destructive) { showDeleteConfirm = true } label: {
            Label("Delete Room", systemImage: "trash")
        }
    }

    @ViewBuilder
    private var sortMenu: some View {
        Menu {
            ForEach(SortMode.allCases, id: \.self) { mode in
                Button {
                    if mode == .custom && !isPremium {
                        showPaywall = true
                    } else {
                        declutterManager.sortMode = mode
                        declutterManager.applySorting()
                    }
                } label: {
                    if declutterManager.sortMode == mode {
                        Label(mode.label, systemImage: "checkmark")
                    } else {
                        Label(mode.label, systemImage: mode.icon)
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    @ViewBuilder
    private var premiumMenuItems: some View {
        Button {
            if isPremium {
                snapshotManager.takeSnapshot(roomId: roomId, items: declutterManager.items)
                showSnapshotConfirm = true
            } else { showPaywall = true }
        } label: {
            Label("Take Snapshot", systemImage: "camera.metering.spot")
        }

        Button {
            if isPremium { showSnapshotHistory = true } else { showPaywall = true }
        } label: {
            Label("Snapshot History", systemImage: "clock.arrow.circlepath")
        }

        Button {
            if isPremium { showScienceView = true } else { showPaywall = true }
        } label: {
            Label("Here Comes the Science", systemImage: "brain.head.profile")
        }

        Button {
            if isPremium {
                if declutterManager.isAutogrouped {
                    declutterManager.clearAutogroups(roomId: roomId)
                } else {
                    declutterManager.autogroupItems(roomId: roomId)
                }
            } else { showPaywall = true }
        } label: {
            Label(
                declutterManager.isAutogrouped ? "Clear Autogroup" : "Autogroup Items",
                systemImage: "rectangle.3.group"
            )
        }
    }

    @ViewBuilder
    private var importMenuItems: some View {
        Button { importFromICloud() } label: {
            Label("Import Items from iCloud", systemImage: "icloud.and.arrow.down")
        }
        Button { showFileImporter = true } label: {
            Label("Import from File...", systemImage: "doc.text")
        }
        Button { pasteItems() } label: {
            Label("Paste Items from Clipboard", systemImage: "doc.on.clipboard")
        }
    }

    // MARK: - Sheets

    private func scienceSheet(_ room: Room) -> some View {
        NavigationStack {
            ScienceView(
                roomType: room.icon.rawValue,
                itemCount: room.itemCount,
                categorizedCount: room.categorizedCount
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showScienceView = false }
                }
            }
        }
    }

    private func snapshotHistorySheet(_ room: Room) -> some View {
        NavigationStack {
            SnapshotHistoryView(roomId: roomId, roomName: room.name)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showSnapshotHistory = false }
                    }
                }
        }
    }

    // MARK: - Actions

    private func importFromICloud() {
        if let icloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents/cleanup2_import.txt"),
           FileManager.default.fileExists(atPath: icloudURL.path) {
            importFromFile(url: icloudURL)
            return
        }

        let names = ["cleanup2_import.txt", "cleanup2_paste_items.txt"]
        if let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
            for name in names {
                let url = container.appendingPathComponent("Documents/\(name)")
                try? FileManager.default.startDownloadingUbiquitousItem(at: url)
                if FileManager.default.fileExists(atPath: url.path) {
                    importFromFile(url: url)
                    return
                }
            }
        }

        importErrorMessage = "No import file found in iCloud Drive. AirDrop photos to Mac, run /cleanup2 scan from Claude Code, then try again."
        showImportError = true
    }

    private func importFromFile(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty else {
            importErrorMessage = "Could not read file or file is empty."
            showImportError = true
            return
        }
        let itemNames = DeclutterManager.parseItemNames(from: text)
        guard !itemNames.isEmpty else {
            importErrorMessage = "No items found in file."
            showImportError = true
            return
        }
        declutterManager.addItems(roomId: roomId, names: itemNames)
        roomManager.loadRooms()
        importedItemCount = itemNames.count
        showImportConfirm = true
    }

    private func pasteItems() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        let itemNames = DeclutterManager.parseItemNames(from: text)
        guard !itemNames.isEmpty else { return }
        declutterManager.addItems(roomId: roomId, names: itemNames)
        roomManager.loadRooms()
        pastedItemCount = itemNames.count
        showPasteConfirm = true
    }

    private func toggleVoiceInput() {
        if isRecordingVoice {
            speechService.stopTranscribing()
            isRecordingVoice = false
            let itemNames = DeclutterManager.parseItemNames(from: speechService.transcript)
            if !itemNames.isEmpty {
                declutterManager.addItems(roomId: roomId, names: itemNames)
                roomManager.loadRooms()
            }
            speechService.transcript = ""
        } else {
            speechService.startTranscribing()
            isRecordingVoice = true
        }
    }
}

// MARK: - Circular Progress View

private struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.indigo, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold))
        }
    }
}

// MARK: - Item Row

private struct ItemRowView: View {
    let item: DeclutterItem
    let roomId: Int64
    @EnvironmentObject var declutterManager: DeclutterManager
    @EnvironmentObject var roomManager: RoomManager

    var body: some View {
        HStack {
            photoThumbnail
            itemDetails
            Spacer()
            categoryMenu
        }
    }

    @ViewBuilder
    private var photoThumbnail: some View {
        if let photoPath = item.photoPath,
           let image = PhotoStorageService.shared.loadPhoto(relativePath: photoPath) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var itemDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(item.name).font(.body)
                if item.isFurniture {
                    Image(systemName: "chair.lounge.fill")
                        .font(.caption2).foregroundStyle(.brown)
                }
            }
            if let group = item.autoGroup {
                Text(group)
                    .font(.caption2)
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(.indigo.opacity(0.1))
                    .foregroundStyle(.indigo)
                    .clipShape(Capsule())
            }
            if let notes = item.notes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var categoryMenu: some View {
        let currentCategory = item.category
        Menu {
            ForEach(ItemCategory.allCases.filter { $0 != currentCategory }) { cat in
                Button {
                    declutterManager.categorize(itemId: item.id, category: cat, roomId: roomId)
                    roomManager.loadRooms()
                } label: {
                    Label(cat.label, systemImage: cat.icon)
                }
            }
            Divider()
            Button {
                declutterManager.toggleFurniture(itemId: item.id, isFurniture: !item.isFurniture, roomId: roomId)
                roomManager.loadRooms()
            } label: {
                Label(item.isFurniture ? "Not Furniture" : "Mark as Furniture", systemImage: "chair.lounge.fill")
            }
        } label: {
            CategoryBadgeView(category: currentCategory)
        }
    }
}

// MARK: - Rename Room Sheet

struct RenameRoomSheet: View {
    let roomId: Int64
    let currentName: String
    @Binding var isPresented: Bool
    @EnvironmentObject var roomManager: RoomManager
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Room Name", text: $name)
            }
            .navigationTitle("Rename Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        roomManager.updateRoom(id: roomId, name: trimmed)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { name = currentName }
        }
        .presentationDetents([.medium])
    }
}
