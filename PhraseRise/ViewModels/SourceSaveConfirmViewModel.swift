import Foundation
import Observation

@Observable
@MainActor
final class SourceSaveConfirmViewModel {
    private let draftID: UUID
    private let draftRepository: SourceCaptureDraftRepository
    private let sourceSongCreationService: SourceSongCreationService
    private let waveformAnalysisService: WaveformAnalysisService
    private let audioPreviewService: AudioPreviewService

    var draft: SourceCaptureDraft?
    var title = ""
    var waveformValues: [Double] = Array(repeating: 0.2, count: 48)
    var isSaving = false
    var isPreviewPlaying = false
    var errorMessage: String?
    private(set) var didSave = false

    init(
        draftID: UUID,
        draftRepository: SourceCaptureDraftRepository,
        sourceSongCreationService: SourceSongCreationService,
        waveformAnalysisService: WaveformAnalysisService,
        audioPreviewService: AudioPreviewService
    ) {
        self.draftID = draftID
        self.draftRepository = draftRepository
        self.sourceSongCreationService = sourceSongCreationService
        self.waveformAnalysisService = waveformAnalysisService
        self.audioPreviewService = audioPreviewService
    }

    func load() {
        guard let draft = draftRepository.fetch(id: draftID) else {
            errorMessage = "録音下書きを読み込めませんでした。"
            return
        }

        self.draft = draft
        if title.isEmpty {
            title = defaultTitle(for: draft.createdAt)
        }

        do {
            waveformValues = try waveformAnalysisService.analyzeWaveform(url: draft.tempFileURL, sampleCount: 48)
        } catch {
            waveformValues = Array(repeating: 0.22, count: 48)
        }
    }

    func togglePreview() {
        guard let draft else { return }
        do {
            isPreviewPlaying = try audioPreviewService.togglePreview(for: draft.tempFileURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSong() -> Song? {
        guard let draft else { return nil }

        isSaving = true
        defer { isSaving = false }

        do {
            audioPreviewService.stopPreview()
            isPreviewPlaying = false
            let song = try sourceSongCreationService.createSong(from: draft, title: title)
            didSave = true
            return song
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func stopPreview() {
        audioPreviewService.stopPreview()
        isPreviewPlaying = false
    }

    func discardDraftIfNeeded() {
        guard !didSave, let draft else { return }
        stopPreview()
        try? FileManager.default.removeItem(at: draft.tempFileURL)
        draftRepository.delete(draft)
        self.draft = nil
    }

    private func defaultTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 HH:mm"
        return "練習音源 \(formatter.string(from: date))"
    }
}
