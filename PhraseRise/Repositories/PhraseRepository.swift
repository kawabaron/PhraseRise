import Foundation
import SwiftData

@MainActor
final class PhraseRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() -> [Phrase] {
        let descriptor = FetchDescriptor<Phrase>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetch(songId: UUID) -> [Phrase] {
        let descriptor = FetchDescriptor<Phrase>(
            predicate: #Predicate<Phrase> { phrase in
                phrase.songId == songId
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetch(id: UUID) -> Phrase? {
        let descriptor = FetchDescriptor<Phrase>(predicate: #Predicate<Phrase> { phrase in
            phrase.id == id
        })
        return (try? context.fetch(descriptor))?.first
    }

    @discardableResult
    func create(
        songId: UUID,
        name: String,
        memo: String? = nil,
        startTimeSec: Double,
        endTimeSec: Double,
        targetBpm: Int? = nil,
        priority: Int = 1,
        status: PhraseStatus = .active,
        lastStableBpm: Int? = nil,
        bestStableBpm: Int? = nil,
        recommendedStartBpm: Int? = nil,
        recommendedNextBpm: Int? = nil,
        nextPracticeDate: Date? = nil
    ) -> Phrase {
        let phrase = Phrase(
            songId: songId,
            name: name,
            memo: memo,
            startTimeSec: startTimeSec,
            endTimeSec: endTimeSec,
            targetBpm: targetBpm,
            lastStableBpm: lastStableBpm,
            bestStableBpm: bestStableBpm,
            recommendedStartBpm: recommendedStartBpm,
            recommendedNextBpm: recommendedNextBpm,
            priority: priority,
            status: status,
            nextPracticeDate: nextPracticeDate
        )
        context.insert(phrase)
        save()
        return phrase
    }

    func save(_ phrase: Phrase) {
        phrase.updatedAt = .now
        save()
    }

    func delete(_ phrase: Phrase) {
        context.delete(phrase)
        save()
    }

    private func save() {
        try? context.save()
    }
}
