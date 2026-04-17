import Foundation
import Observation

@Observable
@MainActor
final class StatsViewModel {
    private let dependencies: AppDependencies
    private let subscriptionService: SubscriptionService

    var songs: [Song] = []
    var phrases: [Phrase] = []
    var selectedSongID: UUID?
    var selectedPhraseID: UUID?
    var selectedPeriod: StatsPeriodFilter = .last30Days

    var totalPracticeCount = 0
    var totalPracticeSeconds = 0
    var stableRate = 0.0
    var recordingCount = 0
    var recentStableTrend: [StatsPoint] = []
    var paywallMessage: String?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        subscriptionService = dependencies.subscriptionService
        refresh()
    }

    var isPremium: Bool {
        subscriptionService.state.isPremium
    }

    var availablePhrases: [Phrase] {
        guard let selectedSongID else { return phrases }
        return phrases.filter { $0.songId == selectedSongID }
    }

    func refresh() {
        songs = dependencies.songRepository.fetchAll()
        phrases = dependencies.phraseRepository.fetchAll()
        applyFilters()
    }

    @discardableResult
    func selectPeriod(_ period: StatsPeriodFilter) -> Bool {
        if period == .allTime {
            switch subscriptionService.gateAllTimeStats() {
            case .allowed:
                break
            case let .blocked(reason):
                paywallMessage = reason
                return false
            }
        }

        selectedPeriod = period
        applyFilters()
        return true
    }

    func selectSong(_ songID: UUID?) {
        selectedSongID = songID
        if let selectedPhraseID, !availablePhrases.contains(where: { $0.id == selectedPhraseID }) {
            self.selectedPhraseID = nil
        }
        applyFilters()
    }

    func selectPhrase(_ phraseID: UUID?) {
        selectedPhraseID = phraseID
        applyFilters()
    }

    private func applyFilters() {
        let allRecords = dependencies.practiceRecordRepository.fetchAll()
        let allRecordings = dependencies.performanceRecordingRepository.fetchAll()
        let phraseMap = Dictionary(uniqueKeysWithValues: phrases.map { ($0.id, $0) })

        let dateThreshold = thresholdDate(for: selectedPeriod)
        let filteredRecords = allRecords.filter { record in
            if let selectedPhraseID, record.phraseId != selectedPhraseID {
                return false
            }
            if let selectedSongID {
                guard let phrase = phraseMap[record.phraseId], phrase.songId == selectedSongID else {
                    return false
                }
            }
            if let dateThreshold, record.practicedAt < dateThreshold {
                return false
            }
            return true
        }

        let filteredRecordings = allRecordings.filter { recording in
            if let selectedPhraseID, recording.phraseId != selectedPhraseID {
                return false
            }
            if let selectedSongID {
                guard let phrase = phraseMap[recording.phraseId], phrase.songId == selectedSongID else {
                    return false
                }
            }
            if let dateThreshold, recording.recordedAt < dateThreshold {
                return false
            }
            return true
        }

        totalPracticeCount = filteredRecords.count
        totalPracticeSeconds = filteredRecords.reduce(0) { $0 + $1.practiceDurationSec }
        recordingCount = filteredRecordings.count

        let stableCount = filteredRecords.filter { $0.resultType == .stable }.count
        stableRate = filteredRecords.isEmpty ? 0 : Double(stableCount) / Double(filteredRecords.count)

        recentStableTrend = filteredRecords
            .sorted { $0.practicedAt < $1.practicedAt }
            .suffix(selectedPeriod == .last7Days ? 7 : 12)
            .map {
                StatsPoint(label: Formatting.date($0.practicedAt), bpm: $0.triedBpm)
            }
    }

    private func thresholdDate(for period: StatsPeriodFilter) -> Date? {
        switch period {
        case .last7Days:
            return Calendar.current.date(byAdding: .day, value: -7, to: .now)
        case .last30Days:
            return Calendar.current.date(byAdding: .day, value: -30, to: .now)
        case .allTime:
            return nil
        }
    }
}
