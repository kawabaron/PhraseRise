import Foundation
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
                // スキーマ変更などで既存ストアの読み込みに失敗した場合は、
                // 一度ストアを削除して作り直す（開発中のデータ消失を許容する簡易リカバリ）。
                Self.removeStoreFiles(named: "PhraseRise")
                do {
                    container = try ModelContainer(for: schema, configurations: configuration)
                } catch {
                    fatalError("Failed to create ModelContainer after reset: \(error)")
                }
            }
        }

        private static func removeStoreFiles(named name: String) {
            let fm = FileManager.default
            guard let appSupport = try? fm.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ) else { return }

            for suffix in ["store", "store-shm", "store-wal"] {
                let url = appSupport.appendingPathComponent("\(name).\(suffix)")
                try? fm.removeItem(at: url)
            }
        }
    }
}
