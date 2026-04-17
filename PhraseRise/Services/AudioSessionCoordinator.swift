import AVFoundation
import UIKit

enum MicrophonePermissionState {
    case undetermined
    case denied
    case granted
}

@MainActor
final class AudioSessionCoordinator {
    private let session = AVAudioSession.sharedInstance()

    func microphonePermissionStatus() -> MicrophonePermissionState {
        switch session.recordPermission {
        case .undetermined:
            return .undetermined
        case .denied:
            return .denied
        case .granted:
            return .granted
        @unknown default:
            return .denied
        }
    }

    func requestMicrophonePermission() async -> MicrophonePermissionState {
        let current = microphonePermissionStatus()
        guard current == .undetermined else {
            return current
        }

        return await withCheckedContinuation { continuation in
            session.requestRecordPermission { granted in
                continuation.resume(returning: granted ? .granted : .denied)
            }
        }
    }

    func configureForSourceCapture() throws {
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }

    func configureForPreviewPlayback() throws {
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
    }

    func deactivate() {
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
