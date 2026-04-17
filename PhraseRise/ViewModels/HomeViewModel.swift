import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    private let dependencies: AppDependencies

    var todayPhrases: [PhraseSnapshot] = []
    var recentPhrases: [PhraseSnapshot] = []
    var recentRecordings: [RecordingSnapshot] = []

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        refresh()
    }

    func refresh() {
        let songsById = Dictionary(uniqueKeysWithValues: dependencies.songRepository.fetchAll().map { ($0.id, $0) })
        let recordsByPhraseId = Dictionary(grouping: dependencies.practiceRecordRepository.fetchAll(), by: \.phraseId)
        let recordingsByPhraseId = Dictionary(grouping: dependencies.performanceRecordingRepository.fetchAll(), by: \.phraseId)

        let snapshots = dependencies.phraseRepository.fetchAll().compactMap { phrase -> PhraseSnapshot? in
            guard let song = songsById[phrase.songId] else { return nil }
            return PhraseSnapshot(
                id: phrase.id,
                phrase: phrase,
                song: song,
                latestRecord: recordsByPhraseId[phrase.id]?.sorted(by: { $0.practicedAt > $1.practicedAt }).first,
                hasRecording: !(recordingsByPhraseId[phrase.id] ?? []).isEmpty
            )
        }

        todayPhrases = snapshots
            .sorted {
                ($0.phrase.nextPracticeDate ?? .distantFuture) < ($1.phrase.nextPracticeDate ?? .distantFuture)
            }
        recentPhrases = snapshots
            .sorted { $0.phrase.updatedAt > $1.phrase.updatedAt }
            .prefix(4)
            .map { $0 }

        let phrasesById = Dictionary(uniqueKeysWithValues: dependencies.phraseRepository.fetchAll().map { ($0.id, $0) })
        recentRecordings = dependencies.performanceRecordingRepository.fetchAll()
            .compactMap { recording -> RecordingSnapshot? in
                guard let phrase = phrasesById[recording.phraseId],
                      let song = songsById[phrase.songId] else {
                    return nil
                }
                return RecordingSnapshot(id: recording.id, recording: recording, phraseName: phrase.name, songTitle: song.title)
            }
            .prefix(4)
            .map { $0 }
    }
}
