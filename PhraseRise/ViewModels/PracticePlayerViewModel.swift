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
    private let clickTrackService: ClickTrackService
    private let settingsRepository: SettingsRepository

    @ObservationIgnored
    private lazy var progressTicker = PlaybackProgressTicker(interval: 0.05) { [weak self] in
        self?.refreshProgress()
    }
    private let referenceBpm: Int
    private var countInTask: Task<Void, Never>?

    var isPlaying = false
    var isLoopEnabled: Bool
    var isCountInEnabled: Bool
    var isCountingIn = false
    var isRecording = false
    var bpm: Int
    var pitchSemitones: Int = 0
    var currentTimeSec: Double
    var loopRange: ClosedRange<Double>
    var recordingElapsedSec: Double = 0
    var recordingInputLevel: Double = 0
    var latestRecordingSummary: String
    var hasLatestRecording: Bool
    var errorMessage: String?
    var shouldShowPaywall = false

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.phrase = phrase
        self.song = song
        audioPlaybackService = dependencies.audioPlaybackService
        performanceRecordingService = dependencies.performanceRecordingService
        phraseLoopService = dependencies.phraseLoopService
        performanceRecordingRepository = dependencies.performanceRecordingRepository
        clickTrackService = dependencies.clickTrackService
        settingsRepository = dependencies.settingsRepository

        let initialRange = dependencies.phraseLoopService.initialRange(for: phrase, song: song)
        let initialBpm = phrase.recommendedStartBpm ?? phrase.lastStableBpm ?? phrase.targetBpm ?? 88
        loopRange = initialRange
        currentTimeSec = initialRange.lowerBound
        bpm = initialBpm
        let settings = dependencies.settingsRepository.loadOrCreate()
        isLoopEnabled = settings.defaultLoopEnabled
        isCountInEnabled = settings.countInClickEnabled
        referenceBpm = max(40, phrase.targetBpm ?? phrase.bestStableBpm ?? phrase.lastStableBpm ?? initialBpm)

        hasLatestRecording = false
        latestRecordingSummary = "演奏録音はまだありません"
        refreshLatestRecordingSummary()
    }

    func toggleCountIn() {
        isCountInEnabled.toggle()
        let settings = settingsRepository.loadOrCreate()
        settings.countInClickEnabled = isCountInEnabled
        settingsRepository.save(settings)
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

    var loopDurationLabel: String {
        Formatting.duration(loopRange.upperBound - loopRange.lowerBound)
    }

    var targetBpmLabel: String {
        phrase.targetBpm.map { "\($0) BPM" } ?? "--"
    }

    func handleAppear() {
        audioPlaybackService.setCursor(loopRange.lowerBound)
        currentTimeSec = loopRange.lowerBound
        progressTicker.start()
    }

    func handleDisappear() {
        progressTicker.stop()
        cancelCountIn()
        if performanceRecordingService.isRecording {
            performanceRecordingService.discardActiveRecording()
        }
        audioPlaybackService.stop()
        isPlaying = false
        isRecording = false
    }

    func togglePlayback() {
        if isCountingIn {
            cancelCountIn()
            return
        }

        if isPlaying {
            audioPlaybackService.pause()
            currentTimeSec = audioPlaybackService.playbackTime()
            isPlaying = false
            return
        }

        let startTime = (currentTimeSec < loopRange.lowerBound || currentTimeSec > loopRange.upperBound)
            ? loopRange.lowerBound
            : currentTimeSec

        if isCountInEnabled {
            startCountInThenPlay(from: startTime)
        } else {
            startActualPlayback(from: startTime)
        }
    }

    private func startActualPlayback(from startTime: Double) {
        do {
            try audioPlaybackService.play(url: song.localFileURL, from: startTime, rate: playbackRate)
            currentTimeSec = startTime
            isPlaying = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startCountInThenPlay(from startTime: Double) {
        isCountingIn = true
        let clickBpm = max(40, bpm)
        countInTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.clickTrackService.playCountIn(bpm: clickBpm, beatCount: 4)
            guard !Task.isCancelled, self.isCountingIn else { return }
            self.isCountingIn = false
            self.startActualPlayback(from: startTime)
        }
    }

    private func cancelCountIn() {
        countInTask?.cancel()
        countInTask = nil
        clickTrackService.cancelPending()
        isCountingIn = false
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

    func setPitch(_ semitones: Int) {
        let clamped = min(max(semitones, -12), 12)
        pitchSemitones = clamped
        audioPlaybackService.updatePitch(semitones: clamped)
    }

    func setLoopRange(fromRatio ratio: ClosedRange<Double>) {
        let newStart = ratio.lowerBound * song.durationSec
        let newEnd = ratio.upperBound * song.durationSec
        loopRange = phraseLoopService.clampRange(
            start: newStart,
            end: newEnd,
            songDurationSec: song.durationSec
        )
        if currentTimeSec < loopRange.lowerBound {
            currentTimeSec = loopRange.lowerBound
            audioPlaybackService.setCursor(currentTimeSec)
        } else if currentTimeSec > loopRange.upperBound {
            currentTimeSec = loopRange.upperBound
            audioPlaybackService.setCursor(currentTimeSec)
        }
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
                let nsError = error as NSError
                if nsError.code == 402 {
                    shouldShowPaywall = true
                }
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

    private func refreshProgress() {
        if isRecording {
            recordingElapsedSec = performanceRecordingService.elapsedSec
            recordingInputLevel = performanceRecordingService.inputLevel
        } else if recordingInputLevel != 0 {
            recordingInputLevel = 0
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
