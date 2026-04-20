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

    @ObservationIgnored
    private lazy var progressTicker = PlaybackProgressTicker(interval: 0.05) { [weak self] in
        self?.refreshProgress()
    }

    static let speedPercentRange: ClosedRange<Int> = 50 ... 200
    static let speedPercentStep: Int = 5

    var isPlaying = false
    var isLoopEnabled: Bool
    var isRecording = false
    var speedPercent: Int = 100
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

        let initialRange = dependencies.phraseLoopService.initialRange(for: phrase, song: song)
        loopRange = initialRange
        currentTimeSec = initialRange.lowerBound
        let settings = dependencies.settingsRepository.loadOrCreate()
        isLoopEnabled = settings.defaultLoopEnabled

        hasLatestRecording = false
        latestRecordingSummary = "演奏録音はまだありません"
        refreshLatestRecordingSummary()
    }

    var playbackRate: Float {
        Float(speedPercent) / 100.0
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

    func setSpeedPercent(_ value: Int) {
        let clamped = min(max(value, Self.speedPercentRange.lowerBound), Self.speedPercentRange.upperBound)
        speedPercent = clamped
        audioPlaybackService.updateRate(playbackRate)
    }

    func handleAppear() {
        audioPlaybackService.setCursor(loopRange.lowerBound)
        currentTimeSec = loopRange.lowerBound
        progressTicker.start()
    }

    func handleDisappear() {
        progressTicker.stop()
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

        startActualPlayback(from: startTime)
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
            try await performanceRecordingService.startRecording(phraseID: phrase.id)
            isRecording = true
            recordingElapsedSec = 0
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshProgress() {
        if isRecording {
            performanceRecordingService.refreshInputLevel()
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
            latestRecordingSummary = Formatting.date(latestRecording.recordedAt)
        } else {
            latestRecordingSummary = "演奏録音はまだありません"
        }
    }
}
