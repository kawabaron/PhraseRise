import Foundation
import Observation

@Observable
@MainActor
final class PhraseEditorViewModel {
    private let song: Song
    private let existingPhrase: Phrase?
    private let phraseRepository: PhraseRepository
    private let subscriptionService: SubscriptionService

    var name: String
    var memo: String
    var targetBpm: Int
    var startRatio: Double
    var endRatio: Double
    var errorMessage: String?

    init(song: Song, phrase: Phrase?, dependencies: AppDependencies) {
        self.song = song
        existingPhrase = phrase
        phraseRepository = dependencies.phraseRepository
        subscriptionService = dependencies.subscriptionService

        name = phrase?.name ?? "新しい Phrase"
        memo = phrase?.memo ?? ""
        targetBpm = phrase?.targetBpm ?? 96

        if let phrase, song.durationSec > 0 {
            startRatio = min(max(phrase.startTimeSec / song.durationSec, 0), 1)
            endRatio = min(max(phrase.endTimeSec / song.durationSec, 0.05), 1)
        } else {
            startRatio = 0.18
            endRatio = min(0.42, song.durationSec > 0 ? 0.42 : 0.55)
        }
    }

    var waveformValues: [Double] {
        song.waveformOverview.isEmpty ? Array(repeating: 0.36, count: 48) : song.waveformOverview
    }

    var startTimeSec: Double {
        song.durationSec * startRatio
    }

    var endTimeSec: Double {
        song.durationSec * endRatio
    }

    var selectedDurationSec: Double {
        max(0, endTimeSec - startTimeSec)
    }

    func nudgeStart(by seconds: Double) {
        guard song.durationSec > 0 else { return }
        let next = startTimeSec + seconds
        startRatio = min(max(next / song.durationSec, 0), max(endRatio - 0.02, 0))
    }

    func nudgeEnd(by seconds: Double) {
        guard song.durationSec > 0 else { return }
        let next = endTimeSec + seconds
        endRatio = max(min(next / song.durationSec, 1), min(startRatio + 0.02, 1))
    }

    func savePhrase() -> Phrase? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "フレーズ名を入力してください。"
            return nil
        }

        guard selectedDurationSec >= 0.3 else {
            errorMessage = "A/B 範囲が短すぎます。"
            return nil
        }

        if let existingPhrase {
            existingPhrase.name = trimmedName
            existingPhrase.memo = memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo
            existingPhrase.startTimeSec = startTimeSec
            existingPhrase.endTimeSec = endTimeSec
            existingPhrase.targetBpm = targetBpm
            phraseRepository.save(existingPhrase)
            return existingPhrase
        }

        let currentCount = phraseRepository.fetchAll().count
        switch subscriptionService.gatePhraseCreation(currentCount: currentCount) {
        case .allowed:
            break
        case let .blocked(reason):
            errorMessage = reason
            return nil
        }

        return phraseRepository.create(
            songId: song.id,
            name: trimmedName,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo,
            startTimeSec: startTimeSec,
            endTimeSec: endTimeSec,
            targetBpm: targetBpm,
            priority: 1,
            status: .active,
            recommendedStartBpm: max(40, targetBpm - 8),
            recommendedNextBpm: targetBpm,
            nextPracticeDate: .now
        )
    }
}
