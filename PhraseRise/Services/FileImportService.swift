import AVFoundation
import Foundation

@MainActor
final class FileImportService {
    private let songRepository: SongRepository
    private let waveformAnalysisService: WaveformAnalysisService
    private let fileManager = FileManager.default

    init(songRepository: SongRepository, waveformAnalysisService: WaveformAnalysisService) {
        self.songRepository = songRepository
        self.waveformAnalysisService = waveformAnalysisService
    }

    func importSong(from sourceURL: URL) throws -> Song {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let songsDirectory = try AudioFileStorage.songsDirectory(fileManager: fileManager)
        let fileExtension = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let destinationURL = AudioFileStorage.uniqueAudioFileURL(in: songsDirectory, fileExtension: fileExtension)

        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        let durationSec = waveformAnalysisService.durationSec(for: destinationURL)
        let waveform = (try? waveformAnalysisService.analyzeWaveform(url: destinationURL, sampleCount: 64))
            ?? makePlaceholderWaveform(for: destinationURL)

        return songRepository.create(
            title: sourceURL.deletingPathExtension().lastPathComponent,
            localFileURL: destinationURL,
            durationSec: durationSec.isFinite ? durationSec : 0,
            sourceType: .imported,
            waveformOverview: waveform
        )
    }

    private func makePlaceholderWaveform(for fileURL: URL) -> [Double] {
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 1_024
        return (0 ..< 48).map { index in
            let value = ((fileSize / max(index + 1, 1)) % 17) + 4
            return min(0.9, max(0.18, Double(value) / 22.0))
        }
    }
}
