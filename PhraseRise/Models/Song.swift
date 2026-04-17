import Foundation
import SwiftData

@Model
final class Song {
    @Attribute(.unique) var id: UUID
    var title: String
    var artistName: String?
    var localFileURL: URL
    var durationSec: Double
    var sourceTypeRaw: String
    var waveformOverviewJSON: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        artistName: String? = nil,
        localFileURL: URL,
        durationSec: Double,
        sourceType: SongSourceType,
        waveformOverview: [Double] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.localFileURL = localFileURL
        self.durationSec = durationSec
        self.sourceTypeRaw = sourceType.rawValue
        self.waveformOverviewJSON = Self.encodeWaveform(waveformOverview)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var sourceType: SongSourceType {
        get { SongSourceType(rawValue: sourceTypeRaw) ?? .imported }
        set { sourceTypeRaw = newValue.rawValue }
    }

    var waveformOverview: [Double] {
        get { Self.decodeWaveform(waveformOverviewJSON) }
        set { waveformOverviewJSON = Self.encodeWaveform(newValue) }
    }

    private static func encodeWaveform(_ values: [Double]) -> String {
        guard let data = try? JSONEncoder().encode(values),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }

    private static func decodeWaveform(_ string: String) -> [Double] {
        guard let data = string.data(using: .utf8),
              let values = try? JSONDecoder().decode([Double].self, from: data) else {
            return []
        }
        return values
    }
}
