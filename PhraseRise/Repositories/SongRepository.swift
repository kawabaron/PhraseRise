import Foundation
import SwiftData

@MainActor
final class SongRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() -> [Song] {
        let descriptor = FetchDescriptor<Song>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func fetch(id: UUID) -> Song? {
        let descriptor = FetchDescriptor<Song>(predicate: #Predicate<Song> { song in
            song.id == id
        })
        return (try? context.fetch(descriptor))?.first
    }

    @discardableResult
    func create(
        title: String,
        artistName: String? = nil,
        localFileURL: URL,
        durationSec: Double,
        sourceType: SongSourceType,
        waveformOverview: [Double] = []
    ) -> Song {
        let song = Song(
            title: title,
            artistName: artistName,
            localFileURL: localFileURL,
            durationSec: durationSec,
            sourceType: sourceType,
            waveformOverview: waveformOverview
        )
        context.insert(song)
        save()
        return song
    }

    func save(_ song: Song) {
        song.updatedAt = .now
        save()
    }

    func delete(_ song: Song) {
        context.delete(song)
        save()
    }

    private func save() {
        try? context.save()
    }
}
