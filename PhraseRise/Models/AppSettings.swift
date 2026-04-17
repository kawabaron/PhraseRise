import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var defaultTempoStep: Int
    var defaultLoopEnabled: Bool
    var reminderEnabled: Bool
    var showHeadphoneHint: Bool
    var recordingQualityPreset: String

    init(
        id: UUID = UUID(),
        defaultTempoStep: Int = 2,
        defaultLoopEnabled: Bool = true,
        reminderEnabled: Bool = false,
        showHeadphoneHint: Bool = true,
        recordingQualityPreset: String = "high"
    ) {
        self.id = id
        self.defaultTempoStep = defaultTempoStep
        self.defaultLoopEnabled = defaultLoopEnabled
        self.reminderEnabled = reminderEnabled
        self.showHeadphoneHint = showHeadphoneHint
        self.recordingQualityPreset = recordingQualityPreset
    }
}
