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

    func refresh() {
        practiceRecords = dependencies.practiceRecordRepository.fetch(phraseId: phrase.id)
        recordings = dependencies.performanceRecordingRepository.fetch(phraseId: phrase.id)
    }

    var chartPoints: [StatsPoint] {
        practiceRecords
            .sorted { $0.practicedAt < $1.practicedAt }
            .map {
                StatsPoint(
                    label: Formatting.date($0.practicedAt),
                    bpm: $0.triedBpm
                )
            }
    }
}
