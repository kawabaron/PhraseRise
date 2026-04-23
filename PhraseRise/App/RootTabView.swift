import SwiftUI

private enum AppTab: String, CaseIterable, Identifiable {
    case today
    case library
    case progress
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .library:
            return "Library"
        case .progress:
            return "Progress"
        case .settings:
            return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .today:
            return "sparkles"
        case .library:
            return "music.note.list"
        case .progress:
            return "chart.line.uptrend.xyaxis"
        case .settings:
            return "gearshape"
        }
    }
}

struct RootTabView: View {
    let dependencies: AppDependencies
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView(dependencies: dependencies)
            }
            .tabItem {
                Label(AppTab.today.title, systemImage: AppTab.today.symbol)
            }
            .tag(AppTab.today)

            NavigationStack {
                SongsView(dependencies: dependencies)
            }
            .tabItem {
                Label(AppTab.library.title, systemImage: AppTab.library.symbol)
            }
            .tag(AppTab.library)

            NavigationStack {
                StatsView(dependencies: dependencies)
            }
            .tabItem {
                Label(AppTab.progress.title, systemImage: AppTab.progress.symbol)
            }
            .tag(AppTab.progress)

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
