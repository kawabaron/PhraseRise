import Foundation
import Observation

@Observable
@MainActor
final class PhraseDetailViewModel {
    private let dependencies: AppDependencies
    let phrase: Phrase
    let song: Song

    var practiceRecords: [PracticeRecord] = []
    var recordings: [PerformanceRecording] = []

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.phrase = phrase
        self.song = song
        self.dependencies = dependencies
        refresh()
    }

    var isPremium: Bool {
        dependencies.subscriptionService.state.isPremium
    }

    func refresh() {
        practiceRecords = dependencies.practiceRecordRepository.fetch(phraseId: phrase.id)
        recordings = dependencies.performanceRecordingRepository.fetch(phraseId: phrase.id)
    }

    var chartPoints: [StatsPoint] {
        let history = isPremium ? practiceRecords : Array(practiceRecords.prefix(8))
        return history
            .sorted { $0.practicedAt < $1.practicedAt }
            .map {
                StatsPoint(label: Formatting.date($0.practicedAt), bpm: $0.triedBpm)
            }
    }

    var totalPracticeMinutes: Int {
        practiceRecords.reduce(0) { $0 + $1.practiceDurationSec } / 60
    }

    var stableRate: Int {
        guard !practiceRecords.isEmpty else { return 0 }
        let stableCount = practiceRecords.filter { $0.resultType == .stable }.count
        return Int((Double(stableCount) / Double(practiceRecords.count)) * 100)
    }

    var nextSuggestionSummary: String {
        let start = phrase.recommendedStartBpm.map { "\($0)" } ?? "--"
        let next = phrase.recommendedNextBpm.map { "\($0)" } ?? "--"
        return "次回開始 \(start) BPM / 次回目標 \(next) BPM"
    }
}
