import SwiftUI

@main
@MainActor
struct PhraseRiseApp: App {
    private let dependencies = AppDependencies.shared

    var body: some Scene {
        WindowGroup {
            RootTabView(dependencies: dependencies)
                .task {
                    dependencies.bootstrap()
                }
        }
        .modelContainer(AppDatabase.shared.container)
    }
}
