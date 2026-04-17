import Foundation
import SwiftData

@Model
final class PerformanceRecording {
    @Attribute(.unique) var id: UUID
    var phraseId: UUID
    var practiceRecordId: UUID?
    var fileURL: URL
    var durationSec: Double
    var recordedAt: Date
    var bpmAtRecording: Int?
    var resultTypeRaw: String?
    var takeName: String
    var fileSizeBytes: Int64

    init(
        id: UUID = UUID(),
        phraseId: UUID,
        practiceRecordId: UUID? = nil,
        fileURL: URL,
        durationSec: Double,
        recordedAt: Date = .now,
        bpmAtRecording: Int? = nil,
        resultType: PracticeResultType? = nil,
        takeName: String,
        fileSizeBytes: Int64 = 0
    ) {
        self.id = id
        self.phraseId = phraseId
        self.practiceRecordId = practiceRecordId
        self.fileURL = fileURL
        self.durationSec = durationSec
        self.recordedAt = recordedAt
        self.bpmAtRecording = bpmAtRecording
        self.resultTypeRaw = resultType?.rawValue
        self.takeName = takeName
        self.fileSizeBytes = fileSizeBytes
    }

    var resultType: PracticeResultType? {
        get {
            guard let resultTypeRaw else { return nil }
            return PracticeResultType(rawValue: resultTypeRaw)
        }
        set {
            resultTypeRaw = newValue?.rawValue
        }
    }
}
