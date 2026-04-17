import SwiftData

@MainActor
enum AppDatabase {
    static let shared = SharedDatabase()

    @MainActor
    final class SharedDatabase {
        let container: ModelContainer

        init() {
            let schema = Schema([
                Song.self,
                Phrase.self,
                PracticeRecord.self,
                PerformanceRecording.self,
                SourceCaptureDraft.self,
                AppSettings.self,
                SubscriptionState.self
            ])

            let configuration = ModelConfiguration("PhraseRise", schema: schema, isStoredInMemoryOnly: false)

            do {
                container = try ModelContainer(for: schema, configurations: configuration)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }
}
