import Foundation
import SwiftData

@MainActor
final class PracticeRecordRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() -> [PracticeRecord] {
        let descriptor = FetchDescriptor<PracticeRecord>(sortBy: [SortDescriptor(\.practicedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetch(phraseId: UUID) -> [PracticeRecord] {
        let descriptor = FetchDescriptor<PracticeRecord>(
            predicate: #Predicate<PracticeRecord> { record in
                record.phraseId == phraseId
            },
            sortBy: [SortDescriptor(\.practicedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    @discardableResult
    func create(
        phraseId: UUID,
        practicedAt: Date = .now,
        triedBpm: Int,
        resultType: PracticeResultType,
        practiceDurationSec: Int,
        notes: String? = nil,
        linkedPerformanceRecordingId: UUID? = nil
    ) -> PracticeRecord {
        let record = PracticeRecord(
            phraseId: phraseId,
            practicedAt: practicedAt,
            triedBpm: triedBpm,
            resultType: resultType,
            practiceDurationSec: practiceDurationSec,
            notes: notes,
            linkedPerformanceRecordingId: linkedPerformanceRecordingId
        )
        context.insert(record)
        save()
        return record
    }

    func save(_ record: PracticeRecord) {
        _ = record
        save()
    }

    func delete(_ record: PracticeRecord) {
        context.delete(record)
        save()
    }

    private func save() {
        try? context.save()
    }
}
