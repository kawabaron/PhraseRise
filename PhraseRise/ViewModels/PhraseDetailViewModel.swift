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
    var isPlaying = false
    var progress: Double = 0
    var errorMessage: String?

    @ObservationIgnored
    private lazy var progressTicker = PlaybackProgressTicker(interval: 0.1) { [weak self] in
        self?.checkProgress()
    }

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

    var totalPracticeMinutes: Int {
        practiceRecords.reduce(0) { $0 + $1.practiceDurationSec } / 60
    }

    var stableRate: Int {
        guard !practiceRecords.isEmpty else { return 0 }
        let stableCount = practiceRecords.filter { $0.resultType == .stable }.count
        return Int((Double(stableCount) / Double(practiceRecords.count)) * 100)
    }

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
            return
        }

        do {
            try dependencies.audioPlaybackService.play(
                url: song.localFileURL,
                from: phrase.startTimeSec,
                rate: 1
            )
            isPlaying = true
            progress = 0
            progressTicker.start()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopPlayback() {
        progressTicker.stop()
        dependencies.audioPlaybackService.stop()
        isPlaying = false
        progress = 0
    }

    private func checkProgress() {
        guard isPlaying else { return }
        let now = dependencies.audioPlaybackService.playbackTime()
        let duration = max(phrase.endTimeSec - phrase.startTimeSec, 0.01)
        progress = min(max((now - phrase.startTimeSec) / duration, 0), 1)
        if now >= phrase.endTimeSec || !dependencies.audioPlaybackService.isPlaying {
            stopPlayback()
        }
    }
}
