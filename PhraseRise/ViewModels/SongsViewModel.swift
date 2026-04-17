import Foundation
import Observation

@Observable
@MainActor
final class SongsViewModel {
    private let dependencies: AppDependencies

    var songs: [Song] = []

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        refresh()
    }

    func refresh() {
        songs = dependencies.songRepository.fetchAll()
    }
}
