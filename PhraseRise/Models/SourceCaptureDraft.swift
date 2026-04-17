import Foundation
import SwiftData

@Model
final class SourceCaptureDraft {
    @Attribute(.unique) var id: UUID
    var tempFileURL: URL
    var durationSec: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        tempFileURL: URL,
        durationSec: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.tempFileURL = tempFileURL
        self.durationSec = durationSec
        self.createdAt = createdAt
    }
}
