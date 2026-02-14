import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var cleaningManager: CleaningManager

    var body: some View {
        TabView {
            DeclutterTabView()
                .tabItem {
                    Label("Declutter", systemImage: "archivebox.fill")
                }

            CleanTabView()
                .tabItem {
                    Label("Clean", systemImage: "sparkles")
                }
                .badge(cleaningManager.dueTasks.count)

            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
        .tint(.indigo)
    }
}
