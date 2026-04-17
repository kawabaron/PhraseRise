import Foundation
import SwiftData

@MainActor
final class SettingsRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadOrCreate() -> AppSettings {
        if let existing = (try? context.fetch(FetchDescriptor<AppSettings>()))?.first {
            return existing
        }

        let settings = AppSettings()
        context.insert(settings)
        save()
        return settings
    }

    func save(_ settings: AppSettings) {
        _ = settings
        save()
    }

    private func save() {
        try? context.save()
    }
}
