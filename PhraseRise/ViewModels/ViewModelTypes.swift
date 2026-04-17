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
