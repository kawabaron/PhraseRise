import Foundation
import SwiftData

@MainActor
final class PerformanceRecordingRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() -> [PerformanceRecording] {
        let descriptor = FetchDescriptor<PerformanceRecording>(sortBy: [SortDescriptor(\.recordedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetch(phraseId: UUID) -> [PerformanceRecording] {
        let descriptor = FetchDescriptor<PerformanceRecording>(
            predicate: #Predicate<PerformanceRecording> { recording in
                recording.phraseId == phraseId
            },
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    @discardableResult
    func create(
        phraseId: UUID,
        practiceRecordId: UUID? = nil,
        fileURL: URL,
        durationSec: Double,
        recordedAt: Date = .now,
        resultType: PracticeResultType? = nil,
        takeName: String,
        fileSizeBytes: Int64 = 0
    ) -> PerformanceRecording {
        let recording = PerformanceRecording(
            phraseId: phraseId,
            practiceRecordId: practiceRecordId,
            fileURL: fileURL,
            durationSec: durationSec,
            recordedAt: recordedAt,
            resultType: resultType,
            takeName: takeName,
            fileSizeBytes: fileSizeBytes
        )
        context.insert(recording)
        save()
        return recording
    }

    func save(_ recording: PerformanceRecording) {
        _ = recording
        save()
    }

    func delete(_ recording: PerformanceRecording) {
        context.delete(recording)
        save()
    }

    private func save() {
        try? context.save()
    }
}
