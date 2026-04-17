import Foundation
import Observation

@Observable
@MainActor
final class SongDetailViewModel {
    private let dependencies: AppDependencies
    let song: Song

    var phrases: [Phrase] = []

    init(song: Song, dependencies: AppDependencies) {
        self.song = song
        self.dependencies = dependencies
        refresh()
    }

    func refresh() {
        phrases = dependencies.phraseRepository.fetch(songId: song.id)
    }

    var waveformValues: [Double] {
        song.waveformOverview.isEmpty ? Array(repeating: 0.36, count: 42) : song.waveformOverview
    }
}
