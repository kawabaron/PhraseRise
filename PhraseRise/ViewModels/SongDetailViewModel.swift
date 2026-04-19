import Foundation
import Observation

@Observable
@MainActor
final class SongDetailViewModel {
    private let dependencies: AppDependencies
    let song: Song

    var phrases: [Phrase] = []
    var errorMessage: String?
    var playingPhraseID: UUID?
    var playingPhraseProgress: Double = 0
    var isSongPlaying = false
    var songPlaybackRatio: Double = 0

    private nonisolated(unsafe) var progressTimer: Timer?
    private var playingStartTimeSec: Double = 0
    private var playingEndTimeSec: Double = 0

    init(song: Song, dependencies: AppDependencies) {
        self.song = song
        self.dependencies = dependencies
        refresh()
    }

    deinit {
        progressTimer?.invalidate()
    }

    func refresh() {
        phrases = dependencies.phraseRepository.fetch(songId: song.id)
    }

    func deletePhrase(_ phrase: Phrase) {
        if playingPhraseID == phrase.id {
            stopPlayback()
        }
        dependencies.phraseDeletionService.deletePhrase(phrase)
        refresh()
    }

    func deleteSong() {
        stopPlayback()
        dependencies.songDeletionService.deleteSong(song)
    }

    func togglePhrasePlayback(_ phrase: Phrase) {
        if playingPhraseID == phrase.id {
            stopPlayback()
            return
        }

        stopPlayback()

        do {
            try dependencies.audioPlaybackService.play(
                url: song.localFileURL,
                from: phrase.startTimeSec,
                rate: 1
            )
            playingPhraseID = phrase.id
            playingStartTimeSec = phrase.startTimeSec
            playingEndTimeSec = phrase.endTimeSec
            playingPhraseProgress = 0
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSongPlayback() {
        if isSongPlaying {
            stopPlayback()
            return
        }

        stopPlayback()

        do {
            try dependencies.audioPlaybackService.play(
                url: song.localFileURL,
                from: 0,
                rate: 1
            )
            isSongPlaying = true
            playingStartTimeSec = 0
            playingEndTimeSec = song.durationSec
            songPlaybackRatio = 0
            startTimer()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopPlayback() {
        stopTimer()
        dependencies.audioPlaybackService.stop()
        playingPhraseID = nil
        playingPhraseProgress = 0
        isSongPlaying = false
        songPlaybackRatio = 0
        playingStartTimeSec = 0
        playingEndTimeSec = 0
    }

    var waveformValues: [Double] {
        song.waveformOverview.isEmpty ? Array(repeating: 0.36, count: 42) : song.waveformOverview
    }

    private func startTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPlaybackProgress()
            }
        }
    }

    private func stopTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func checkPlaybackProgress() {
        guard playingPhraseID != nil || isSongPlaying else { return }
        let now = dependencies.audioPlaybackService.playbackTime()
        if isSongPlaying, song.durationSec > 0 {
            songPlaybackRatio = min(max(now / song.durationSec, 0), 1)
        }
        if playingPhraseID != nil {
            let duration = max(playingEndTimeSec - playingStartTimeSec, 0.01)
            playingPhraseProgress = min(max((now - playingStartTimeSec) / duration, 0), 1)
        }
        if now >= playingEndTimeSec || !dependencies.audioPlaybackService.isPlaying {
            stopPlayback()
        }
    }
}
