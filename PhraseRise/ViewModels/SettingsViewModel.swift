import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    private let dependencies: AppDependencies
    private let audioSessionCoordinator: AudioSessionCoordinator
    private let subscriptionService: SubscriptionService

    var settings: AppSettings
    var subscription: SubscriptionState
    var microphonePermission: MicrophonePermissionState

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        audioSessionCoordinator = dependencies.audioSessionCoordinator
        subscriptionService = dependencies.subscriptionService
        settings = dependencies.settingsRepository.loadOrCreate()
        subscription = subscriptionService.state
        microphonePermission = audioSessionCoordinator.microphonePermissionStatus()
    }

    var microphonePermissionLabel: String {
        switch microphonePermission {
        case .undetermined:
            return "未確認"
        case .denied:
            return "未許可"
        case .granted:
            return "許可済み"
        }
    }

    var premiumStatusLabel: String {
        subscription.isPremium ? "Premium 利用中" : "無料版"
    }

    func updateTempoStep(_ value: Int) {
        settings.defaultTempoStep = value
        dependencies.settingsRepository.save(settings)
    }

    func updateLoopDefault(_ isEnabled: Bool) {
        settings.defaultLoopEnabled = isEnabled
        dependencies.settingsRepository.save(settings)
    }

    func updateReminder(_ isEnabled: Bool) {
        settings.reminderEnabled = isEnabled
        dependencies.settingsRepository.save(settings)
    }

    func updateHeadphoneHint(_ isEnabled: Bool) {
        settings.showHeadphoneHint = isEnabled
        dependencies.settingsRepository.save(settings)
    }

    func updateRecordingQuality(_ preset: String) {
        settings.recordingQualityPreset = preset
        dependencies.settingsRepository.save(settings)
    }

    func refreshPermissionState() {
        microphonePermission = audioSessionCoordinator.microphonePermissionStatus()
    }

    func requestMicrophonePermission() async {
        microphonePermission = await audioSessionCoordinator.requestMicrophonePermission()
    }

    func openSystemSettings() {
        audioSessionCoordinator.openAppSettings()
    }

    func enablePremium() {
        subscriptionService.enablePremiumDemo(productType: .lifetime)
        subscription = subscriptionService.state
    }

    func restoreFree() {
        subscriptionService.restoreFreeDemo()
        subscription = subscriptionService.state
    }
}
