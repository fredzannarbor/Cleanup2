import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var cleaningManager: CleaningManager
    @State private var selectedTab: Int = {
        let args = CommandLine.arguments
        if let idx = args.firstIndex(of: "-tab"), idx + 1 < args.count,
           let tab = Int(args[idx + 1]) {
            return tab
        }
        return 0
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            DeclutterTabView()
                .tabItem {
                    Label("Declutter", systemImage: "archivebox.fill")
                }
                .tag(0)

            CleanTabView()
                .tabItem {
                    Label("Clean", systemImage: "sparkles")
                }
                .badge(cleaningManager.dueTasks.count)
                .tag(1)

            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .tint(.indigo)
    }
}
