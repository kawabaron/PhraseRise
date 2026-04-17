import AVFoundation
import Foundation

@MainActor
final class FileImportService {
    private let songRepository: SongRepository
    private let fileManager = FileManager.default

    init(songRepository: SongRepository) {
        self.songRepository = songRepository
    }

    func importSong(from sourceURL: URL) throws -> Song {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let songsDirectory = try ensureSongsDirectory()
        let fileExtension = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let destinationURL = songsDirectory.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")

        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        let asset = AVURLAsset(url: destinationURL)
        let durationSec = max(0, CMTimeGetSeconds(asset.duration))
        let waveform = makePlaceholderWaveform(for: destinationURL)

        return songRepository.create(
            title: sourceURL.deletingPathExtension().lastPathComponent,
            localFileURL: destinationURL,
            durationSec: durationSec.isFinite ? durationSec : 0,
            sourceType: .imported,
            waveformOverview: waveform
        )
    }

    private func ensureSongsDirectory() throws -> URL {
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = appSupport.appendingPathComponent("PhraseRise/Songs", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private func makePlaceholderWaveform(for fileURL: URL) -> [Double] {
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 1_024
        return (0 ..< 48).map { index in
            let value = ((fileSize / max(index + 1, 1)) % 17) + 4
            return min(0.9, max(0.18, Double(value) / 22.0))
        }
    }
}
