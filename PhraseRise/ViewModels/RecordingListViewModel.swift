import Foundation
import Observation

@Observable
@MainActor
final class RecordingListViewModel {
    private let phrase: Phrase
    private let performanceRecordingRepository: PerformanceRecordingRepository
    private let practiceRecordRepository: PracticeRecordRepository
    private let audioPreviewService: AudioPreviewService
    private let subscriptionService: SubscriptionService

    var recordings: [PerformanceRecording] = []
    var selectedRecordingIDs: [UUID] = []
    var playingRecordingID: UUID?
    var errorMessage: String?
    var paywallMessage: String?

    init(phrase: Phrase, song: Song, dependencies: AppDependencies) {
        self.phrase = phrase
        _ = song
        performanceRecordingRepository = dependencies.performanceRecordingRepository
        practiceRecordRepository = dependencies.practiceRecordRepository
        audioPreviewService = dependencies.audioPreviewService
        subscriptionService = dependencies.subscriptionService
        refresh()
    }

    var isPremium: Bool {
        subscriptionService.state.isPremium
    }

    var canCompare: Bool {
        selectedRecordingIDs.count == 2
    }

    var selectedRecordings: [PerformanceRecording] {
        selectedRecordingIDs.compactMap { id in
            recordings.first(where: { $0.id == id })
        }
    }

    var compareTitle: String {
        canCompare ? "比較対象を切り替えながら聞けます" : "2件選ぶと比較再生できます"
    }

    func refresh() {
        recordings = performanceRecordingRepository.fetch(phraseId: phrase.id)
    }

    func toggleSelection(_ recording: PerformanceRecording) {
        if let index = selectedRecordingIDs.firstIndex(of: recording.id) {
            selectedRecordingIDs.remove(at: index)
            return
        }

        if selectedRecordingIDs.count == 2 {
            selectedRecordingIDs.removeFirst()
        }
        selectedRecordingIDs.append(recording.id)
    }

    func playSingle(_ recording: PerformanceRecording) {
        do {
            let isPlaying = try audioPreviewService.togglePreview(for: recording.fileURL)
            playingRecordingID = isPlaying ? recording.id : nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func playComparison() {
        guard startComparisonIfAllowed() else { return }
        guard selectedRecordings.count == 2 else { return }

        let nextRecording: PerformanceRecording
        if let playingRecordingID,
           let currentIndex = selectedRecordings.firstIndex(where: { $0.id == playingRecordingID }) {
            let nextIndex = (currentIndex + 1) % selectedRecordings.count
            nextRecording = selectedRecordings[nextIndex]
        } else {
            nextRecording = selectedRecordings[0]
        }

        playSingle(nextRecording)
    }

    func stopPreview() {
        audioPreviewService.stopPreview()
        playingRecordingID = nil
    }

    func startComparisonIfAllowed() -> Bool {
        guard canCompare else {
            errorMessage = "比較したい演奏録音を2件選択してください。"
            return false
        }

        switch subscriptionService.gateRecordingComparison() {
        case .allowed:
            return true
        case let .blocked(reason):
            paywallMessage = reason
            return false
        }
    }

    func hasLinkedMemo(for recording: PerformanceRecording) -> Bool {
        if let practiceRecordID = recording.practiceRecordId,
           let record = practiceRecordRepository.fetchAll().first(where: { $0.id == practiceRecordID }) {
            return !(record.notes?.isEmpty ?? true)
        }

        if let record = practiceRecordRepository.fetchAll().first(where: { $0.linkedPerformanceRecordingId == recording.id }) {
            return !(record.notes?.isEmpty ?? true)
        }

        return false
    }

    func delete(_ recording: PerformanceRecording) {
        if playingRecordingID == recording.id {
            stopPreview()
        }

        for record in practiceRecordRepository.fetchAll() where record.linkedPerformanceRecordingId == recording.id {
            record.linkedPerformanceRecordingId = nil
            practiceRecordRepository.save(record)
        }

        try? FileManager.default.removeItem(at: recording.fileURL)
        performanceRecordingRepository.delete(recording)
        selectedRecordingIDs.removeAll { $0 == recording.id }
        refresh()
    }
}
