import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    private let dependencies: AppDependencies

    var settings: AppSettings
    var subscription: SubscriptionState

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.settings = dependencies.settingsRepository.loadOrCreate()
        self.subscription = dependencies.subscriptionRepository.loadOrCreate()
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
}
