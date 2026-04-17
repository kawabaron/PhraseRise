import Foundation

@MainActor
final class PhraseDeletionService {
    private let phraseRepository: PhraseRepository
    private let practiceRecordRepository: PracticeRecordRepository
    private let performanceRecordingRepository: PerformanceRecordingRepository
    private let fileManager: FileManager

    init(
        phraseRepository: PhraseRepository,
        practiceRecordRepository: PracticeRecordRepository,
        performanceRecordingRepository: PerformanceRecordingRepository,
        fileManager: FileManager = .default
    ) {
        self.phraseRepository = phraseRepository
        self.practiceRecordRepository = practiceRecordRepository
        self.performanceRecordingRepository = performanceRecordingRepository
        self.fileManager = fileManager
    }

    func deletePhrase(_ phrase: Phrase) {
        let recordings = performanceRecordingRepository.fetch(phraseId: phrase.id)
        for recording in recordings {
            try? fileManager.removeItem(at: recording.fileURL)
            performanceRecordingRepository.delete(recording)
        }

        let phraseDirectory = try? AudioFileStorage.performanceRecordingsDirectory(phraseID: phrase.id, fileManager: fileManager)
        if let phraseDirectory {
            try? fileManager.removeItem(at: phraseDirectory)
        }

        for record in practiceRecordRepository.fetch(phraseId: phrase.id) {
            practiceRecordRepository.delete(record)
        }

        phraseRepository.delete(phrase)
    }
}
