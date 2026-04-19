import Foundation
import SwiftData

@Model
final class PracticeRecord {
    @Attribute(.unique) var id: UUID
    var phraseId: UUID
    var practicedAt: Date
    var resultTypeRaw: String
    var practiceDurationSec: Int
    var notes: String?
    var linkedPerformanceRecordingId: UUID?

    init(
        id: UUID = UUID(),
        phraseId: UUID,
        practicedAt: Date = .now,
        resultType: PracticeResultType,
        practiceDurationSec: Int,
        notes: String? = nil,
        linkedPerformanceRecordingId: UUID? = nil
    ) {
        self.id = id
        self.phraseId = phraseId
        self.practicedAt = practicedAt
        self.resultTypeRaw = resultType.rawValue
        self.practiceDurationSec = practiceDurationSec
        self.notes = notes
        self.linkedPerformanceRecordingId = linkedPerformanceRecordingId
    }

    var resultType: PracticeResultType {
        get { PracticeResultType(rawValue: resultTypeRaw) ?? .failed }
        set { resultTypeRaw = newValue.rawValue }
    }
}
