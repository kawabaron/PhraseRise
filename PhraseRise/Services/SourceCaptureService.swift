import AVFoundation
import Foundation

struct SourceCaptureOutput {
    let fileURL: URL
    let durationSec: Double
}

@MainActor
final class SourceCaptureService: NSObject {
    private let audioSessionCoordinator: AudioSessionCoordinator
    private var recorder: AVAudioRecorder?
    private var activeFileURL: URL?

    init(audioSessionCoordinator: AudioSessionCoordinator) {
        self.audioSessionCoordinator = audioSessionCoordinator
    }

    var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    var hasPreparedCapture: Bool {
        recorder != nil
    }

    var elapsedSec: Double {
        recorder?.currentTime ?? 0
    }

    private(set) var inputLevel: Double = 0

    /// 呼び出し元のタイマーから定期的に叩いてもらい、最新のメーター値を `inputLevel` に反映する。
    func refreshInputLevel() {
        guard let recorder else {
            inputLevel = 0
            return
        }
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        let normalized = pow(10, power / 20)
        inputLevel = min(1, max(0, Double(normalized)))
    }

    func startCapture(recordingQualityPreset: String) throws {
        guard recorder == nil else {
            throw NSError(
                domain: "PhraseRise.SourceCapture",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "既に録音が進行中です。"]
            )
        }

        try audioSessionCoordinator.configureForSourceCapture()

        let draftsDirectory = try AudioFileStorage.draftsDirectory()
        let draftURL = AudioFileStorage.uniqueAudioFileURL(in: draftsDirectory, fileExtension: "m4a")

        let recorder = try AVAudioRecorder(url: draftURL, settings: recordingSettings(for: recordingQualityPreset))
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
        guard recorder.record() else {
            throw NSError(
                domain: "PhraseRise.SourceCapture",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "録音を開始できませんでした。"]
            )
        }

        self.recorder = recorder
        self.activeFileURL = draftURL
    }

    func pauseCapture() {
        recorder?.pause()
    }

    func resumeCapture() {
        recorder?.record()
    }

    func stopCapture() throws -> SourceCaptureOutput {
        guard let recorder, let activeFileURL else {
            throw NSError(
                domain: "PhraseRise.SourceCapture",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "停止できる録音がありません。"]
            )
        }

        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        self.activeFileURL = nil
        audioSessionCoordinator.deactivate()

        return SourceCaptureOutput(fileURL: activeFileURL, durationSec: duration)
    }

    func discardCapture() {
        recorder?.stop()
        if let activeFileURL {
            try? FileManager.default.removeItem(at: activeFileURL)
        }
        recorder = nil
        self.activeFileURL = nil
        audioSessionCoordinator.deactivate()
    }

    private func recordingSettings(for preset: String) -> [String: Any] {
        let bitRate: Int
        let quality: AVAudioQuality

        switch preset {
        case "lossless":
            bitRate = 256_000
            quality = .max
        case "standard":
            bitRate = 96_000
            quality = .medium
        default:
            bitRate = 160_000
            quality = .high
        }

        return [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: bitRate,
            AVEncoderAudioQualityKey: quality.rawValue
        ]
    }
}
