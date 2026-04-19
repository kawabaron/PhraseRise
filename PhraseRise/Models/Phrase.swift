import Foundation
import SwiftData

@Model
final class Phrase {
    @Attribute(.unique) var id: UUID
    var songId: UUID
    var name: String
    var memo: String?
    var startTimeSec: Double
    var endTimeSec: Double
    var priority: Int
    var statusRaw: String
    var nextPracticeDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        songId: UUID,
        name: String,
        memo: String? = nil,
        startTimeSec: Double,
        endTimeSec: Double,
        priority: Int = 1,
        status: PhraseStatus = .active,
        nextPracticeDate: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.songId = songId
        self.name = name
        self.memo = memo
        self.startTimeSec = startTimeSec
        self.endTimeSec = endTimeSec
        self.priority = priority
        self.statusRaw = status.rawValue
        self.nextPracticeDate = nextPracticeDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var status: PhraseStatus {
        get { PhraseStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var durationSec: Double {
        max(0, endTimeSec - startTimeSec)
    }
}
