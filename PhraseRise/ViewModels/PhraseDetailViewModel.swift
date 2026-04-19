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

    private nonisolated(unsafe) var progressTimer: Timer?

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.phrase = phrase
        self.song = song
        self.dependencies = dependencies
        refresh()
    }

    deinit {
        progressTimer?.invalidate()
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
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopPlayback() {
        stopTimer()
        dependencies.audioPlaybackService.stop()
        isPlaying = false
        progress = 0
    }

    private func startTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkProgress()
            }
        }
    }

    private func stopTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
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
