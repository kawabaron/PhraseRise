import Foundation

struct PhraseSnapshot: Identifiable {
    let id: UUID
    let phrase: Phrase
    let song: Song
    let latestRecord: PracticeRecord?
    let hasRecording: Bool
}

struct RecordingSnapshot: Identifiable {
    let id: UUID
    let recording: PerformanceRecording
    let phraseName: String
    let songTitle: String
}

struct StatsPoint: Identifiable {
    let id = UUID()
    let label: String
    let bpm: Int
}

enum StatsPeriodFilter: String, CaseIterable, Identifiable {
    case last7Days
    case last30Days
    case allTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .last7Days:
            return "7日"
        case .last30Days:
            return "30日"
        case .allTime:
            return "全期間"
        }
    }
}
