import Foundation
import Observation

@Observable
@MainActor
final class PhraseEditorViewModel {
    private let song: Song
    private let existingPhrase: Phrase?
    private let phraseRepository: PhraseRepository
    private let subscriptionService: SubscriptionService
    private let audioPlaybackService: AudioPlaybackService

    @ObservationIgnored
    private lazy var progressTicker = PlaybackProgressTicker(interval: 0.05) { [weak self] in
        self?.refreshProgress()
    }

    var name: String
    var memo: String
    var startRatio: Double
    var endRatio: Double
    var isPlaying = false
    var playheadRatio: Double = 0
    var errorMessage: String?
    var shouldShowPaywall = false

    init(song: Song, phrase: Phrase?, dependencies: AppDependencies) {
        self.song = song
        existingPhrase = phrase
        phraseRepository = dependencies.phraseRepository
        subscriptionService = dependencies.subscriptionService
        audioPlaybackService = dependencies.audioPlaybackService

        name = phrase?.name ?? "新しい練習区間"
        memo = phrase?.memo ?? ""

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

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
            return
        }

        guard song.durationSec > 0 else { return }

        do {
            try audioPlaybackService.play(
                url: song.localFileURL,
                from: startTimeSec,
                rate: 1
            )
            isPlaying = true
            playheadRatio = startRatio
            progressTicker.start()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopPlayback() {
        progressTicker.stop()
        audioPlaybackService.stop()
        isPlaying = false
        playheadRatio = 0
    }

    private func refreshProgress() {
        guard isPlaying else { return }
        let now = audioPlaybackService.playbackTime()
        if song.durationSec > 0 {
            playheadRatio = min(max(now / song.durationSec, 0), 1)
        }
        if now >= endTimeSec || !audioPlaybackService.isPlaying {
            stopPlayback()
        }
    }

    func savePhrase() -> Phrase? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "練習区間名を入力してください。"
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
            phraseRepository.save(existingPhrase)
            return existingPhrase
        }

        let currentCount = phraseRepository.fetchAll().count
        switch subscriptionService.gatePhraseCreation(currentCount: currentCount) {
        case .allowed:
            break
        case let .blocked(reason):
            errorMessage = reason
            shouldShowPaywall = true
            return nil
        }

        return phraseRepository.create(
            songId: song.id,
            name: trimmedName,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo,
            startTimeSec: startTimeSec,
            endTimeSec: endTimeSec,
            priority: 1,
            status: .active,
            nextPracticeDate: .now
        )
    }
}
