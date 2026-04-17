import Foundation

@MainActor
final class SongDeletionService {
    private let songRepository: SongRepository
    private let phraseRepository: PhraseRepository
    private let phraseDeletionService: PhraseDeletionService
    private let fileManager: FileManager

    init(
        songRepository: SongRepository,
        phraseRepository: PhraseRepository,
        phraseDeletionService: PhraseDeletionService,
        fileManager: FileManager = .default
    ) {
        self.songRepository = songRepository
        self.phraseRepository = phraseRepository
        self.phraseDeletionService = phraseDeletionService
        self.fileManager = fileManager
    }

    func deleteSong(_ song: Song) {
        for phrase in phraseRepository.fetch(songId: song.id) {
            phraseDeletionService.deletePhrase(phrase)
        }

        try? fileManager.removeItem(at: song.localFileURL)
        songRepository.delete(song)
    }
}
