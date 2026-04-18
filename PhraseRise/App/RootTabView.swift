import SwiftUI

private enum AppTab: String, CaseIterable, Identifiable {
    case songs
    case stats
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .songs:
            return "Songs"
        case .stats:
            return "Stats"
        case .settings:
            return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .songs:
            return "music.note.list"
        case .stats:
            return "chart.line.uptrend.xyaxis"
        case .settings:
            return "gearshape"
        }
    }
}

struct RootTabView: View {
    let dependencies: AppDependencies
    @State private var selectedTab: AppTab = .songs

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                SongsView(dependencies: dependencies)
            }
            .tabItem {
                Label(AppTab.songs.title, systemImage: AppTab.songs.symbol)
            }
            .tag(AppTab.songs)

            NavigationStack {
                StatsView(dependencies: dependencies)
            }
            .tabItem {
                Label(AppTab.stats.title, systemImage: AppTab.stats.symbol)
            }
            .tag(AppTab.stats)

            NavigationStack {
                SettingsView(dependencies: dependencies)
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.symbol)
            }
            .tag(AppTab.settings)
        }
        .tint(AppColors.accent)
        .studioScreen()
    }
}
