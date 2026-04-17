import Foundation
import Observation

@Observable
@MainActor
final class PracticeRecordSheetViewModel {
    private let phrase: Phrase
    private let phraseRepository: PhraseRepository
    private let practiceRecordRepository: PracticeRecordRepository
    private let performanceRecordingRepository: PerformanceRecordingRepository
    private let suggestionEngine: PracticeSuggestionEngine

    var bpm: Int
    var resultType: PracticeResultType = .stable
    var durationMinutes = 10
    var memo = ""
    var linkLatestRecording = true
    var latestRecordingSummary: String
    var errorMessage: String?

    init(phrase: Phrase, initialBpm: Int, dependencies: AppDependencies) {
        self.phrase = phrase
        phraseRepository = dependencies.phraseRepository
        practiceRecordRepository = dependencies.practiceRecordRepository
        performanceRecordingRepository = dependencies.performanceRecordingRepository
        suggestionEngine = dependencies.suggestionEngine
        bpm = initialBpm

        if let latestRecording = performanceRecordingRepository.fetch(phraseId: phrase.id).first {
            let bpmText = latestRecording.bpmAtRecording.map { "\($0) BPM" } ?? "-- BPM"
            latestRecordingSummary = "\(Formatting.date(latestRecording.recordedAt)) / \(bpmText)"
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
            triedBpm: bpm,
            resultType: resultType,
            practiceDurationSec: durationMinutes * 60,
            notes: memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : memo,
            linkedPerformanceRecordingId: latestRecording?.id
        )

        if let latestRecording {
            latestRecording.practiceRecordId = record.id
            latestRecording.resultType = resultType
            if latestRecording.bpmAtRecording == nil {
                latestRecording.bpmAtRecording = bpm
            }
            performanceRecordingRepository.save(latestRecording)
        }

        updatePhraseSummary()
        return record
    }

    private func updatePhraseSummary() {
        let suggestion = suggestionEngine.makeSuggestion(from: bpm, resultType: resultType)

        if resultType == .stable {
            phrase.lastStableBpm = bpm
            phrase.bestStableBpm = max(phrase.bestStableBpm ?? 0, bpm)
        }

        phrase.recommendedStartBpm = suggestion.nextStartBpm
        phrase.recommendedNextBpm = suggestion.nextTargetBpm
        phrase.nextPracticeDate = .now

        if let targetBpm = phrase.targetBpm, bpm >= targetBpm, resultType == .stable {
            phrase.status = .mastered
        } else if phrase.status == .mastered, resultType != .stable {
            phrase.status = .active
        }

        phraseRepository.save(phrase)
    }
}
