import Foundation
import Observation

@Observable
@MainActor
final class StatsViewModel {
    private let dependencies: AppDependencies

    var totalPracticeCount = 0
    var totalPracticeSeconds = 0
    var stableRate = 0.0
    var recordingCount = 0
    var recentStableTrend: [StatsPoint] = []

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        refresh()
    }

    func refresh() {
        let records = dependencies.practiceRecordRepository.fetchAll()
        totalPracticeCount = records.count
        totalPracticeSeconds = records.reduce(0) { $0 + $1.practiceDurationSec }
        recordingCount = dependencies.performanceRecordingRepository.fetchAll().count

        let stableCount = records.filter { $0.resultType == .stable }.count
        stableRate = records.isEmpty ? 0 : Double(stableCount) / Double(records.count)

        recentStableTrend = records
            .sorted { $0.practicedAt < $1.practicedAt }
            .suffix(8)
            .map {
                StatsPoint(label: Formatting.date($0.practicedAt), bpm: $0.triedBpm)
            }
    }
}
