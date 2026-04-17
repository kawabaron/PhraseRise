import Foundation

@MainActor
final class SampleDataSeeder {
    private let songRepository: SongRepository
    private let phraseRepository: PhraseRepository
    private let practiceRecordRepository: PracticeRecordRepository
    private let performanceRecordingRepository: PerformanceRecordingRepository
    private let settingsRepository: SettingsRepository
    private let subscriptionRepository: SubscriptionRepository
    private let suggestionEngine: PracticeSuggestionEngine

    init(
        songRepository: SongRepository,
        phraseRepository: PhraseRepository,
        practiceRecordRepository: PracticeRecordRepository,
        performanceRecordingRepository: PerformanceRecordingRepository,
        settingsRepository: SettingsRepository,
        subscriptionRepository: SubscriptionRepository,
        suggestionEngine: PracticeSuggestionEngine
    ) {
        self.songRepository = songRepository
        self.phraseRepository = phraseRepository
        self.practiceRecordRepository = practiceRecordRepository
        self.performanceRecordingRepository = performanceRecordingRepository
        self.settingsRepository = settingsRepository
        self.subscriptionRepository = subscriptionRepository
        self.suggestionEngine = suggestionEngine
    }

    func seedIfNeeded() {
        guard songRepository.fetchAll().isEmpty else {
            _ = settingsRepository.loadOrCreate()
            _ = subscriptionRepository.loadOrCreate()
            return
        }

        _ = settingsRepository.loadOrCreate()
        _ = subscriptionRepository.loadOrCreate()

        let fileURL = URL(fileURLWithPath: "/tmp/blueriff-demo.m4a")
        let song = songRepository.create(
            title: "Blue Riff Study",
            artistName: "PhraseRise Demo",
            localFileURL: fileURL,
            durationSec: 214,
            sourceType: .imported,
            waveformOverview: Array(repeating: 0.4, count: 48).enumerated().map { index, _ in
                0.22 + (Double((index * 13) % 10) / 20.0)
            }
        )

        let lastStable = 96
        let suggestion = suggestionEngine.makeSuggestion(from: lastStable, resultType: .stable)
        let phraseA = phraseRepository.create(
            songId: song.id,
            name: "3連シフト",
            memo: "右手を深く入れすぎない",
            startTimeSec: 41,
            endTimeSec: 49,
            targetBpm: 110,
            priority: 3,
            status: .active,
            lastStableBpm: lastStable,
            bestStableBpm: 100,
            recommendedStartBpm: suggestion.nextStartBpm,
            recommendedNextBpm: suggestion.nextTargetBpm,
            nextPracticeDate: .now
        )

        let phraseB = phraseRepository.create(
            songId: song.id,
            name: "下降レガート",
            memo: "脱力優先",
            startTimeSec: 88,
            endTimeSec: 96,
            targetBpm: 104,
            priority: 2,
            status: .mastered,
            lastStableBpm: 102,
            bestStableBpm: 106,
            recommendedStartBpm: 100,
            recommendedNextBpm: 104,
            nextPracticeDate: Calendar.current.date(byAdding: .day, value: 2, to: .now)
        )

        let recordingA = performanceRecordingRepository.create(
            phraseId: phraseA.id,
            fileURL: URL(fileURLWithPath: "/tmp/perf-001.m4a"),
            durationSec: 8.2,
            recordedAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            bpmAtRecording: 96,
            resultType: .stable,
            takeName: "Take 01",
            fileSizeBytes: 1_280_000
        )

        _ = performanceRecordingRepository.create(
            phraseId: phraseB.id,
            fileURL: URL(fileURLWithPath: "/tmp/perf-002.m4a"),
            durationSec: 7.5,
            recordedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
            bpmAtRecording: 102,
            resultType: .stable,
            takeName: "Take 02",
            fileSizeBytes: 1_100_000
        )

        _ = practiceRecordRepository.create(
            phraseId: phraseA.id,
            practicedAt: Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now,
            triedBpm: 92,
            resultType: .barely,
            practiceDurationSec: 420,
            notes: "小節頭で焦る"
        )
        _ = practiceRecordRepository.create(
            phraseId: phraseA.id,
            practicedAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            triedBpm: 96,
            resultType: .stable,
            practiceDurationSec: 560,
            notes: "切り返しが安定",
            linkedPerformanceRecordingId: recordingA.id
        )
        _ = practiceRecordRepository.create(
            phraseId: phraseB.id,
            practicedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
            triedBpm: 102,
            resultType: .stable,
            practiceDurationSec: 390,
            notes: "左手の移動が軽い"
        )
    }
}
