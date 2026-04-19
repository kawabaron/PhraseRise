import Foundation
import Observation

@Observable
@MainActor
final class PracticeRecordSheetViewModel {
    private let phrase: Phrase
    private let phraseRepository: PhraseRepository
    private let practiceRecordRepository: PracticeRecordRepository
    private let performanceRecordingRepository: PerformanceRecordingRepository

    var resultType: PracticeResultType = .stable
    var durationMinutes = 10
    var memo = ""
    var linkLatestRecording = true
    var latestRecordingSummary: String
    var errorMessage: String?

    init(phrase: Phrase, dependencies: AppDependencies) {
        self.phrase = phrase
        phraseRepository = dependencies.phraseRepository
        practiceRecordRepository = dependencies.practiceRecordRepository
        performanceRecordingRepository = dependencies.performanceRecordingRepository

        if let latestRecording = performanceRecordingRepository.fetch(phraseId: phrase.id).first {
            latestRecordingSummary = Formatting.date(latestRecording.recordedAt)
        } else {
            latestRecordingSummary = "紐付け可能な演奏録音はありません"
            linkLatestRecording = false
        }
    }

    func saveRecord() -> PracticeRecord? {
        guard durationMinutes > 0 else {
            errorMessage = "練習時間を入力してください。"
            return nil
        }

        let latestRecording = linkLatestRecording ? performanceRecordingRepository.fetch(phraseId: phrase.id).first : nil
        let record = practiceRecordRepository.create(
            phraseId: phrase.id,
            resultType: resultType,
            practiceDurationSec: durationMinutes * 60,
            notes: memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo,
            linkedPerformanceRecordingId: latestRecording?.id
        )

        if let latestRecording {
            latestRecording.practiceRecordId = record.id
            latestRecording.resultType = resultType
            performanceRecordingRepository.save(latestRecording)
        }

        updatePhraseSummary()
        return record
    }

    private func updatePhraseSummary() {
        phrase.nextPracticeDate = .now
        phraseRepository.save(phrase)
    }
}
