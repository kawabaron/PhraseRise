import Foundation
import Observation

@Observable
@MainActor
final class MicSourceRecordViewModel {
    private let audioSessionCoordinator: AudioSessionCoordinator
    private let sourceCaptureService: SourceCaptureService
    private let draftRepository: SourceCaptureDraftRepository
    private let settingsRepository: SettingsRepository

    private var refreshTimer: Timer?

    var permissionState: MicrophonePermissionState
    var isRecording = false
    var isPaused = false
    var elapsedSec: Double = 0
    var inputLevel: Double = 0
    var errorMessage: String?

    init(
        audioSessionCoordinator: AudioSessionCoordinator,
        sourceCaptureService: SourceCaptureService,
        draftRepository: SourceCaptureDraftRepository,
        settingsRepository: SettingsRepository
    ) {
        self.audioSessionCoordinator = audioSessionCoordinator
        self.sourceCaptureService = sourceCaptureService
        self.draftRepository = draftRepository
        self.settingsRepository = settingsRepository
        permissionState = audioSessionCoordinator.microphonePermissionStatus()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func requestPermissionIfNeeded() async {
        permissionState = await audioSessionCoordinator.requestMicrophonePermission()
    }

    func startCapture() async {
        if permissionState == .undetermined {
            await requestPermissionIfNeeded()
        }

        guard permissionState == .granted else {
            errorMessage = "マイク権限が未許可です。設定から PhraseRise のマイク利用を有効にしてください。"
            return
        }

        do {
            try sourceCaptureService.startCapture(
                recordingQualityPreset: settingsRepository.loadOrCreate().recordingQualityPreset
            )
            isRecording = true
            isPaused = false
            startRefreshTimer()
            refreshMetrics()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pauseCapture() {
        sourceCaptureService.pauseCapture()
        isRecording = false
        isPaused = true
        refreshMetrics()
    }

    func resumeCapture() {
        sourceCaptureService.resumeCapture()
        isRecording = true
        isPaused = false
        refreshMetrics()
    }

    func stopCapture() -> UUID? {
        do {
            let output = try sourceCaptureService.stopCapture()
            stopRefreshTimer()
            isRecording = false
            isPaused = false
            elapsedSec = output.durationSec
            inputLevel = 0
            let draft = draftRepository.create(tempFileURL: output.fileURL, durationSec: output.durationSec)
            return draft.id
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func discardCapture() {
        sourceCaptureService.discardCapture()
        stopRefreshTimer()
        isRecording = false
        isPaused = false
        elapsedSec = 0
        inputLevel = 0
    }

    func openSettings() {
        audioSessionCoordinator.openAppSettings()
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMetrics()
            }
        }
    }

    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func refreshMetrics() {
        elapsedSec = sourceCaptureService.elapsedSec
        inputLevel = sourceCaptureService.inputLevel
    }
}
