import Foundation

@MainActor
final class SourceSongCreationService {
    private let songRepository: SongRepository
    private let draftRepository: SourceCaptureDraftRepository
    private let waveformAnalysisService: WaveformAnalysisService
    private let fileManager = FileManager.default

    init(
        songRepository: SongRepository,
        draftRepository: SourceCaptureDraftRepository,
        waveformAnalysisService: WaveformAnalysisService
    ) {
        self.songRepository = songRepository
        self.draftRepository = draftRepository
        self.waveformAnalysisService = waveformAnalysisService
    }

    func createSong(from draft: SourceCaptureDraft, title: String) throws -> Song {
        let songsDirectory = try AudioFileStorage.songsDirectory(fileManager: fileManager)
        let fileExtension = draft.tempFileURL.pathExtension.isEmpty ? "m4a" : draft.tempFileURL.pathExtension
        let destinationURL = AudioFileStorage.uniqueAudioFileURL(in: songsDirectory, fileExtension: fileExtension)

        try fileManager.moveItem(at: draft.tempFileURL, to: destinationURL)

        let waveform = try waveformAnalysisService.analyzeWaveform(url: destinationURL, sampleCount: 64)
        let song = songRepository.create(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "練習音源" : title.trimmingCharacters(in: .whitespacesAndNewlines),
            localFileURL: destinationURL,
            durationSec: max(draft.durationSec, waveformAnalysisService.durationSec(for: destinationURL)),
            sourceType: .micRecorded,
            waveformOverview: waveform
        )

        draftRepository.delete(draft)
        return song
    }
}
