import AVFoundation
import Foundation

@MainActor
final class AudioPlaybackService {
    private let audioSessionCoordinator: AudioSessionCoordinator
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()

    private var currentAudioFile: AVAudioFile?
    private var currentFileURL: URL?
    private var scheduledStartTimeSec: Double = 0
    private var playbackRate: Float = 1

    private(set) var isPlaying = false
    private(set) var currentTimeSec: Double = 0

    init(audioSessionCoordinator: AudioSessionCoordinator) {
        self.audioSessionCoordinator = audioSessionCoordinator
        configureEngine()
    }

    var durationSec: Double {
        guard let currentAudioFile else { return 0 }
        return Double(currentAudioFile.length) / currentAudioFile.processingFormat.sampleRate
    }

    func prepare(url: URL) throws {
        _ = try loadFileIfNeeded(url: url)
    }

    func play(url: URL, from timeSec: Double, rate: Float) throws {
        let audioFile = try loadFileIfNeeded(url: url)
        try audioSessionCoordinator.configureForPreviewPlayback()

        let durationSec = Double(audioFile.length) / audioFile.processingFormat.sampleRate
        let clampedTime = min(max(0, timeSec), durationSec)
        let startFrame = AVAudioFramePosition(clampedTime * audioFile.processingFormat.sampleRate)
        let remainingFrames = max(audioFile.length - startFrame, 0)

        playerNode.stop()
        if !audioEngine.isRunning {
            try audioEngine.start()
        }

        guard remainingFrames > 0 else {
            currentTimeSec = durationSec
            scheduledStartTimeSec = durationSec
            isPlaying = false
            return
        }

        timePitch.rate = rate
        playbackRate = rate
        currentTimeSec = clampedTime
        scheduledStartTimeSec = clampedTime

        let maxFrameCount = AVAudioFramePosition(UInt32.max)
        let frameCount = AVAudioFrameCount(min(remainingFrames, maxFrameCount))

        playerNode.scheduleSegment(
            audioFile,
            startingFrame: startFrame,
            frameCount: frameCount,
            at: nil
        )
        playerNode.play()
        isPlaying = true
    }

    func updateRate(_ rate: Float) {
        playbackRate = rate
        timePitch.rate = rate
    }

    func pause() {
        currentTimeSec = playbackTime()
        playerNode.stop()
        isPlaying = false
    }

    func stop() {
        playerNode.stop()
        isPlaying = false
        currentTimeSec = 0
        scheduledStartTimeSec = 0
        audioSessionCoordinator.deactivate()
    }

    func setCursor(_ timeSec: Double) {
        let duration = durationSec
        currentTimeSec = min(max(0, timeSec), duration)
        scheduledStartTimeSec = currentTimeSec
    }

    func seek(url: URL, to timeSec: Double, autoplay: Bool) throws {
        if autoplay {
            try play(url: url, from: timeSec, rate: playbackRate)
        } else {
            pause()
            setCursor(timeSec)
        }
    }

    func playbackTime() -> Double {
        guard isPlaying,
              let lastRenderTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime)
        else {
            return currentTimeSec
        }

        let elapsed = Double(playerTime.sampleTime) / playerTime.sampleRate
        let value = scheduledStartTimeSec + elapsed
        let duration = durationSec
        return min(max(0, value), duration)
    }

    private func configureEngine() {
        audioEngine.attach(playerNode)
        audioEngine.attach(timePitch)
        audioEngine.connect(playerNode, to: timePitch, format: nil)
        audioEngine.connect(timePitch, to: audioEngine.mainMixerNode, format: nil)
    }

    private func loadFileIfNeeded(url: URL) throws -> AVAudioFile {
        if currentFileURL != url {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw NSError(
                    domain: "PhraseRise.AudioPlayback",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "音源ファイルが見つかりません。"]
                )
            }

            currentAudioFile = try AVAudioFile(forReading: url)
            currentFileURL = url
        }

        guard let currentAudioFile else {
            throw NSError(
                domain: "PhraseRise.AudioPlayback",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "音源を読み込めませんでした。"]
            )
        }

        return currentAudioFile
    }
}
