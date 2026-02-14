import SwiftUI

@main
struct Cleanup2App: App {
    @StateObject private var roomManager = RoomManager()
    @StateObject private var declutterManager = DeclutterManager()
    @StateObject private var cleaningManager = CleaningManager()
    @StateObject private var progressManager = ProgressManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(roomManager)
                .environmentObject(declutterManager)
                .environmentObject(cleaningManager)
                .environmentObject(progressManager)
                .onAppear {
                    roomManager.loadRooms()
                    cleaningManager.loadDueTasks()
                    NotificationService.shared.requestAuthorization()
                    NotificationService.shared.scheduleUpcoming(
                        tasks: cleaningManager.dueTasks
                    )
                }
        }
    }
}
