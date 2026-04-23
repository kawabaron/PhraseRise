import Foundation
import Observation

enum TodayPhraseFilter: String, CaseIterable, Identifiable {
    case active
    case needsWork
    case mastered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active:
            return "Active"
        case .needsWork:
            return "Needs Work"
        case .mastered:
            return "Mastered"
        }
    }
}

@Observable
@MainActor
final class TodayViewModel {
    struct FocusPhrase: Identifiable {
        let phrase: Phrase
        let song: Song
        let weeklyPracticeMinutes: Int
        let latestPracticeRecord: PracticeRecord?
        let latestRecording: PerformanceRecording?
        let lastActivityDate: Date?
        let isNeedsWork: Bool

        var id: UUID { phrase.id }
    }

    struct RecentSource: Identifiable {
        let song: Song
        let phraseCount: Int
        let activePhraseCount: Int

        var id: UUID { song.id }
    }

    struct WeeklySummary {
        var practiceSessions: Int = 0
        var practiceMinutes: Int = 0
        var recordings: Int = 0
        var streakDays: Int = 0
    }

    private let dependencies: AppDependencies

    var resumeItem: FocusPhrase?
    var focusPhrases: [FocusPhrase] = []
    var recentSources: [RecentSource] = []
    var weeklySummary = WeeklySummary()
    var activePhraseCount = 0
    var masteredPhraseCount = 0
    var needsWorkPhraseCount = 0
    var totalSourceCount = 0

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        refresh()
    }

    var hasContent: Bool {
        totalSourceCount > 0 || !focusPhrases.isEmpty
    }

    func refresh() {
        let songs = dependencies.songRepository.fetchAll()
        let phrases = dependencies.phraseRepository.fetchAll()
        let practiceRecords = dependencies.practiceRecordRepository.fetchAll()
        let recordings = dependencies.performanceRecordingRepository.fetchAll()

        totalSourceCount = songs.count

        let songMap = Dictionary(uniqueKeysWithValues: songs.map { ($0.id, $0) })
        let phrasesBySong = Dictionary(grouping: phrases, by: \.songId)
        let recordsByPhrase = Dictionary(grouping: practiceRecords, by: \.phraseId)
        let recordingsByPhrase = Dictionary(grouping: recordings, by: \.phraseId)

        let summaries = phrases.compactMap { phrase -> FocusPhrase? in
            guard let song = songMap[phrase.songId] else { return nil }

            let phraseRecords = recordsByPhrase[phrase.id] ?? []
            let phraseRecordings = recordingsByPhrase[phrase.id] ?? []
            let latestPracticeRecord = phraseRecords.first
            let latestRecording = phraseRecordings.first
            let weeklyPracticeMinutes = Self.weeklyPracticeMinutes(for: phraseRecords)
            let lastActivityDate = Self.lastActivityDate(
                latestPracticeRecord: latestPracticeRecord,
                latestRecording: latestRecording
            )
            let isNeedsWork = Self.isPhraseNeedingWork(
                phrase: phrase,
                latestPracticeRecord: latestPracticeRecord,
                weeklyPracticeMinutes: weeklyPracticeMinutes
            )

            return FocusPhrase(
                phrase: phrase,
                song: song,
                weeklyPracticeMinutes: weeklyPracticeMinutes,
                latestPracticeRecord: latestPracticeRecord,
                latestRecording: latestRecording,
                lastActivityDate: lastActivityDate,
                isNeedsWork: isNeedsWork
            )
        }

        focusPhrases = summaries.sorted(by: Self.sortFocusPhrase)
        resumeItem = Self.resumeItem(from: focusPhrases)

        activePhraseCount = summaries.filter { $0.phrase.status == .active }.count
        masteredPhraseCount = summaries.filter { $0.phrase.status == .mastered }.count
        needsWorkPhraseCount = summaries.filter { $0.isNeedsWork }.count

        recentSources = songs.prefix(4).map { song in
            let songPhrases = phrasesBySong[song.id] ?? []
            let activePhraseCount = songPhrases.filter { $0.status == .active }.count
            return RecentSource(
                song: song,
                phraseCount: songPhrases.count,
                activePhraseCount: activePhraseCount
            )
        }

        let weeklyPracticeRecords = practiceRecords.filter { Self.isWithinLastWeek($0.practicedAt) }
        let weeklyRecordings = recordings.filter { Self.isWithinLastWeek($0.recordedAt) }
        weeklySummary = WeeklySummary(
            practiceSessions: weeklyPracticeRecords.count,
            practiceMinutes: weeklyPracticeRecords.reduce(0) { $0 + ($1.practiceDurationSec / 60) },
            recordings: weeklyRecordings.count,
            streakDays: Self.streakLength(from: practiceRecords)
        )
    }

    func focusPhrases(for filter: TodayPhraseFilter) -> [FocusPhrase] {
        switch filter {
        case .active:
            return focusPhrases.filter { $0.phrase.status == .active }
        case .needsWork:
            return focusPhrases.filter { $0.isNeedsWork }
        case .mastered:
            return focusPhrases.filter { $0.phrase.status == .mastered }
        }
    }

    func count(for filter: TodayPhraseFilter) -> Int {
        switch filter {
        case .active:
            return activePhraseCount
        case .needsWork:
            return needsWorkPhraseCount
        case .mastered:
            return masteredPhraseCount
        }
    }

    private static func resumeItem(from summaries: [FocusPhrase]) -> FocusPhrase? {
        summaries.max { lhs, rhs in
            (lhs.lastActivityDate ?? lhs.phrase.updatedAt) < (rhs.lastActivityDate ?? rhs.phrase.updatedAt)
        } ?? summaries.first
    }

    private static func sortFocusPhrase(lhs: FocusPhrase, rhs: FocusPhrase) -> Bool {
        let lhsScore = focusScore(for: lhs)
        let rhsScore = focusScore(for: rhs)
        if lhsScore == rhsScore {
            return lhs.phrase.updatedAt > rhs.phrase.updatedAt
        }
        return lhsScore > rhsScore
    }

    private static func focusScore(for summary: FocusPhrase) -> Int {
        var score = 0

        switch summary.phrase.status {
        case .active:
            score += 120
        case .mastered:
            score += 30
        case .archived:
            score += 5
        }

        if summary.isNeedsWork {
            score += 90
        }

        if let latestResult = summary.latestPracticeRecord?.resultType {
            switch latestResult {
            case .failed:
                score += 80
            case .barely:
                score += 50
            case .stable:
                score += 12
            }
        } else {
            score += 40
        }

        if summary.weeklyPracticeMinutes == 0 {
            score += 26
        } else if summary.weeklyPracticeMinutes < 10 {
            score += 18
        }

        if let lastActivityDate = summary.lastActivityDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastActivityDate, to: .now).day ?? 0
            score += min(max(daysSince, 0), 14)
        } else {
            score += 20
        }

        return score
    }

    private static func weeklyPracticeMinutes(for records: [PracticeRecord]) -> Int {
        records
            .filter { isWithinLastWeek($0.practicedAt) }
            .reduce(0) { $0 + ($1.practiceDurationSec / 60) }
    }

    private static func lastActivityDate(
        latestPracticeRecord: PracticeRecord?,
        latestRecording: PerformanceRecording?
    ) -> Date? {
        switch (latestPracticeRecord?.practicedAt, latestRecording?.recordedAt) {
        case let (practiceDate?, recordingDate?):
            return max(practiceDate, recordingDate)
        case let (practiceDate?, nil):
            return practiceDate
        case let (nil, recordingDate?):
            return recordingDate
        case (nil, nil):
            return nil
        }
    }

    private static func isPhraseNeedingWork(
        phrase: Phrase,
        latestPracticeRecord: PracticeRecord?,
        weeklyPracticeMinutes: Int
    ) -> Bool {
        guard phrase.status != .mastered else { return false }

        if latestPracticeRecord == nil {
            return true
        }

        if let latestPracticeRecord, latestPracticeRecord.resultType != .stable {
            return true
        }

        if weeklyPracticeMinutes < 6 {
            return true
        }

        return false
    }

    private static func isWithinLastWeek(_ date: Date) -> Bool {
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) else {
            return false
        }
        return date >= weekAgo
    }

    private static func streakLength(from records: [PracticeRecord]) -> Int {
        let calendar = Calendar.current
        let activeDays = Set(records.map { calendar.startOfDay(for: $0.practicedAt) })
        guard !activeDays.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: .now)

        if !activeDays.contains(cursor) {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor),
                  activeDays.contains(previousDay) else {
                return 0
            }
            cursor = previousDay
        }

        while activeDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previousDay
        }

        return streak
    }
}
