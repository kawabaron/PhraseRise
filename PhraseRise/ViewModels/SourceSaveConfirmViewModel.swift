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
    var previewRatio: Double = 0
    var errorMessage: String?
    private(set) var didSave = false

    @ObservationIgnored
    private lazy var progressTicker = PlaybackProgressTicker(interval: 0.05) { [weak self] in
        self?.refreshPreviewProgress()
    }

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
        self.audioPreviewService.onFinish = { [weak self] in
            self?.handlePreviewFinished()
        }
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
            let nowPlaying = try audioPreviewService.togglePreview(for: draft.tempFileURL)
            isPreviewPlaying = nowPlaying
            if nowPlaying {
                previewRatio = 0
                progressTicker.start()
            } else {
                progressTicker.stop()
                previewRatio = 0
            }
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
        progressTicker.stop()
        previewRatio = 0
    }

    private func handlePreviewFinished() {
        isPreviewPlaying = false
        progressTicker.stop()
        previewRatio = 0
    }

    private func refreshPreviewProgress() {
        let duration = audioPreviewService.duration
        guard duration > 0 else { return }
        previewRatio = min(max(audioPreviewService.currentTime / duration, 0), 1)
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
