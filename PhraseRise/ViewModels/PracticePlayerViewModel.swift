import Foundation
import Observation

@Observable
@MainActor
final class PracticePlayerViewModel {
    private let phrase: Phrase
    private let song: Song
    private let audioPlaybackService: AudioPlaybackService
    private let performanceRecordingService: PerformanceRecordingService
    private let phraseLoopService: PhraseLoopService
    private let performanceRecordingRepository: PerformanceRecordingRepository

    private var progressTimer: Timer?
    private let referenceBpm: Int

    var isPlaying = false
    var isLoopEnabled: Bool
    var isRecording = false
    var bpm: Int
    var currentTimeSec: Double
    var loopRange: ClosedRange<Double>
    var recordingElapsedSec: Double = 0
    var latestRecordingSummary: String
    var hasLatestRecording: Bool
    var errorMessage: String?

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.phrase = phrase
        self.song = song
        audioPlaybackService = dependencies.audioPlaybackService
        performanceRecordingService = dependencies.performanceRecordingService
        phraseLoopService = dependencies.phraseLoopService
        performanceRecordingRepository = dependencies.performanceRecordingRepository

        let initialRange = dependencies.phraseLoopService.initialRange(for: phrase, song: song)
        loopRange = initialRange
        currentTimeSec = initialRange.lowerBound
        bpm = phrase.recommendedStartBpm ?? phrase.lastStableBpm ?? phrase.targetBpm ?? 88
        isLoopEnabled = dependencies.settingsRepository.loadOrCreate().defaultLoopEnabled
        referenceBpm = max(40, phrase.targetBpm ?? phrase.bestStableBpm ?? phrase.lastStableBpm ?? bpm)

        hasLatestRecording = false
        latestRecordingSummary = "演奏録音はまだありません"
        refreshLatestRecordingSummary()
    }

    deinit {
        progressTimer?.invalidate()
    }

    var playbackRate: Float {
        min(2.0, max(0.5, Float(bpm) / Float(referenceBpm)))
    }

    var playbackRateLabel: String {
        "\(Int(playbackRate * 100))%"
    }

    var selectionRatio: ClosedRange<Double> {
        phraseLoopService.selectionRatio(for: loopRange, songDurationSec: song.durationSec)
    }

    var headRatio: Double {
        phraseLoopService.headRatio(currentTimeSec: currentTimeSec, songDurationSec: song.durationSec)
    }

    func handleAppear() {
        audioPlaybackService.setCursor(loopRange.lowerBound)
        currentTimeSec = loopRange.lowerBound
        startTimer()
    }

    func handleDisappear() {
        stopTimer()
        if performanceRecordingService.isRecording {
            performanceRecordingService.discardActiveRecording()
        }
        audioPlaybackService.stop()
        isPlaying = false
        isRecording = false
    }

    func togglePlayback() {
        if isPlaying {
            audioPlaybackService.pause()
            currentTimeSec = audioPlaybackService.playbackTime()
            isPlaying = false
            return
        }

        let startTime = (currentTimeSec < loopRange.lowerBound || currentTimeSec > loopRange.upperBound)
            ? loopRange.lowerBound
            : currentTimeSec

        do {
            try audioPlaybackService.play(url: song.localFileURL, from: startTime, rate: playbackRate)
            currentTimeSec = startTime
            isPlaying = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func seek(by deltaSec: Double) {
        let target = phraseLoopService.clampedSeekTarget(
            currentTimeSec: currentTimeSec,
            deltaSec: deltaSec,
            songDurationSec: song.durationSec
        )

        do {
            try audioPlaybackService.seek(url: song.localFileURL, to: target, autoplay: isPlaying)
            currentTimeSec = target
            isPlaying = audioPlaybackService.isPlaying
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setBpm(_ value: Int) {
        bpm = value
        audioPlaybackService.updateRate(playbackRate)
    }

    func toggleLoop() {
        isLoopEnabled.toggle()
    }

    func nudgeLoopStart(by deltaSec: Double) {
        loopRange = phraseLoopService.nudgeStart(range: loopRange, by: deltaSec, songDurationSec: song.durationSec)
        if currentTimeSec < loopRange.lowerBound {
            currentTimeSec = loopRange.lowerBound
            audioPlaybackService.setCursor(currentTimeSec)
        }
    }

    func nudgeLoopEnd(by deltaSec: Double) {
        loopRange = phraseLoopService.nudgeEnd(range: loopRange, by: deltaSec, songDurationSec: song.durationSec)
        if currentTimeSec > loopRange.upperBound {
            currentTimeSec = loopRange.upperBound
            audioPlaybackService.setCursor(currentTimeSec)
        }
    }

    func togglePerformanceRecording() async {
        if isRecording {
            do {
                _ = try performanceRecordingService.stopRecording()
                isRecording = false
                recordingElapsedSec = 0
                refreshLatestRecordingSummary()
            } catch {
                errorMessage = error.localizedDescription
            }
            return
        }

        do {
            try await performanceRecordingService.startRecording(phraseID: phrase.id, bpm: bpm)
            isRecording = true
            recordingElapsedSec = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshProgress()
            }
        }
    }

    private func stopTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func refreshProgress() {
        if isRecording {
            recordingElapsedSec = performanceRecordingService.elapsedSec
        }

        guard isPlaying else { return }
        currentTimeSec = audioPlaybackService.playbackTime()

        switch phraseLoopService.boundaryAction(
            currentTimeSec: currentTimeSec,
            range: loopRange,
            isLoopEnabled: isLoopEnabled,
            songDurationSec: song.durationSec
        ) {
        case .none:
            break
        case let .restart(startTime):
            restartLoop(at: startTime)
        case let .stop(stopTime):
            stopPlayback(at: stopTime)
        }
    }

    private func restartLoop(at startTime: Double) {
        guard isPlaying else { return }

        do {
            try audioPlaybackService.play(url: song.localFileURL, from: startTime, rate: playbackRate)
            currentTimeSec = startTime
            isPlaying = true
        } catch {
            errorMessage = error.localizedDescription
            isPlaying = false
        }
    }

    private func stopPlayback(at timeSec: Double) {
        audioPlaybackService.pause()
        audioPlaybackService.setCursor(timeSec)
        currentTimeSec = timeSec
        isPlaying = false
    }

    private func refreshLatestRecordingSummary() {
        let latestRecording = performanceRecordingRepository.fetch(phraseId: phrase.id).first
        hasLatestRecording = latestRecording != nil
        if let latestRecording {
            let bpmText = latestRecording.bpmAtRecording.map { "\($0) BPM" } ?? "-- BPM"
            latestRecordingSummary = "\(Formatting.date(latestRecording.recordedAt)) / \(bpmText)"
        } else {
            latestRecordingSummary = "演奏録音はまだありません"
        }
    }
}
