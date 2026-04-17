import AVFoundation
import Foundation

@MainActor
final class PerformanceRecordingService {
    private let audioSessionCoordinator: AudioSessionCoordinator
    private let performanceRecordingRepository: PerformanceRecordingRepository
    private let settingsRepository: SettingsRepository
    private let subscriptionService: SubscriptionService

    private var recorder: AVAudioRecorder?
    private var activeFileURL: URL?
    private var activePhraseID: UUID?
    private var activeBpm: Int?

    init(
        audioSessionCoordinator: AudioSessionCoordinator,
        performanceRecordingRepository: PerformanceRecordingRepository,
        settingsRepository: SettingsRepository,
        subscriptionService: SubscriptionService
    ) {
        self.audioSessionCoordinator = audioSessionCoordinator
        self.performanceRecordingRepository = performanceRecordingRepository
        self.settingsRepository = settingsRepository
        self.subscriptionService = subscriptionService
    }

    var isRecording: Bool {
        recorder?.isRecording ?? false
    }

    var elapsedSec: Double {
        recorder?.currentTime ?? 0
    }

    func startRecording(phraseID: UUID, bpm: Int?) async throws {
        let permission = await audioSessionCoordinator.requestMicrophonePermission()
        guard permission == .granted else {
            throw NSError(
                domain: "PhraseRise.PerformanceRecording",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "演奏録音にはマイク権限が必要です。"]
            )
        }

        guard recorder == nil else {
            throw NSError(
                domain: "PhraseRise.PerformanceRecording",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "すでに演奏録音が進行中です。"]
            )
        }

        try audioSessionCoordinator.configureForPerformanceRecording()

        let recordingsDirectory = try AudioFileStorage.performanceRecordingsDirectory(phraseID: phraseID)
        let outputURL = AudioFileStorage.uniqueAudioFileURL(in: recordingsDirectory, fileExtension: "m4a")
        let recorder = try AVAudioRecorder(
            url: outputURL,
            settings: recordingSettings(for: settingsRepository.loadOrCreate().recordingQualityPreset)
        )

        recorder.prepareToRecord()
        guard recorder.record() else {
            throw NSError(
                domain: "PhraseRise.PerformanceRecording",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "演奏録音を開始できませんでした。"]
            )
        }

        self.recorder = recorder
        activeFileURL = outputURL
        activePhraseID = phraseID
        activeBpm = bpm
    }

    func stopRecording() throws -> PerformanceRecording {
        guard let recorder, let activeFileURL, let activePhraseID else {
            throw NSError(
                domain: "PhraseRise.PerformanceRecording",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "停止できる演奏録音がありません。"]
            )
        }

        let duration = recorder.currentTime
        recorder.stop()
        self.recorder = nil

        let currentCount = performanceRecordingRepository.fetchAll().count
        switch subscriptionService.gateRecordingSave(currentCount: currentCount) {
        case .allowed:
            break
        case let .blocked(reason):
            try? FileManager.default.removeItem(at: activeFileURL)
            self.activeFileURL = nil
            self.activePhraseID = nil
            self.activeBpm = nil
            throw NSError(
                domain: "PhraseRise.PerformanceRecording",
                code: 402,
                userInfo: [NSLocalizedDescriptionKey: reason]
            )
        }

        let fileSizeBytes = Int64((try? activeFileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        let existingCount = performanceRecordingRepository.fetch(phraseId: activePhraseID).count
        let takeName = String(format: "Take %02d", existingCount + 1)

        let recording = performanceRecordingRepository.create(
            phraseId: activePhraseID,
            fileURL: activeFileURL,
            durationSec: duration,
            bpmAtRecording: activeBpm,
            takeName: takeName,
            fileSizeBytes: fileSizeBytes
        )

        self.activeFileURL = nil
        self.activePhraseID = nil
        self.activeBpm = nil
        return recording
    }

    func discardActiveRecording() {
        recorder?.stop()
        if let activeFileURL {
            try? FileManager.default.removeItem(at: activeFileURL)
        }
        recorder = nil
        self.activeFileURL = nil
        self.activePhraseID = nil
        self.activeBpm = nil
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
