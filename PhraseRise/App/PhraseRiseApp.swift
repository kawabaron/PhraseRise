import SwiftUI
import SwiftData

@main
@MainActor
struct PhraseRiseApp: App {
    private let dependencies = AppDependencies.shared

    var body: some Scene {
        WindowGroup {
            RootTabView(dependencies: dependencies)
                .preferredColorScheme(.dark)
                .task {
                    dependencies.bootstrap()
                }
        }
        .modelContainer(AppDatabase.shared.container)
    }
}
