import AVFoundation
import Foundation
import UniformTypeIdentifiers

@MainActor
final class FileImportService {
    enum ImportError: LocalizedError {
        case exporterUnavailable
        case exportFailed(Error?)
        case noAudioTrack

        var errorDescription: String? {
            switch self {
            case .exporterUnavailable:
                return "動画からの音声抽出を開始できませんでした。"
            case let .exportFailed(error):
                return error?.localizedDescription ?? "動画からの音声抽出に失敗しました。"
            case .noAudioTrack:
                return "この動画には音声トラックが含まれていません。"
            }
        }
    }

    private let songRepository: SongRepository
    private let waveformAnalysisService: WaveformAnalysisService
    private let fileManager = FileManager.default

    init(songRepository: SongRepository, waveformAnalysisService: WaveformAnalysisService) {
        self.songRepository = songRepository
        self.waveformAnalysisService = waveformAnalysisService
    }

    func importSong(from sourceURL: URL) async throws -> Song {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let songsDirectory = try AudioFileStorage.songsDirectory(fileManager: fileManager)
        let title = sourceURL.deletingPathExtension().lastPathComponent
        let destinationURL: URL

        if Self.isVideo(url: sourceURL) {
            destinationURL = AudioFileStorage.uniqueAudioFileURL(in: songsDirectory, fileExtension: "m4a")
            try await extractAudio(from: sourceURL, to: destinationURL)
        } else {
            let fileExtension = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
            destinationURL = AudioFileStorage.uniqueAudioFileURL(in: songsDirectory, fileExtension: fileExtension)
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }

        let durationSec = waveformAnalysisService.durationSec(for: destinationURL)
        let waveform = (try? waveformAnalysisService.analyzeWaveform(url: destinationURL, sampleCount: 64))
            ?? makePlaceholderWaveform(for: destinationURL)

        return songRepository.create(
            title: title,
            localFileURL: destinationURL,
            durationSec: durationSec.isFinite ? durationSec : 0,
            sourceType: .imported,
            waveformOverview: waveform
        )
    }

    private static func isVideo(url: URL) -> Bool {
        if let type = UTType(filenameExtension: url.pathExtension) {
            if type.conforms(to: .movie) || type.conforms(to: .video) {
                return true
            }
            if type.conforms(to: .audio) {
                return false
            }
        }
        let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "qt", "avi", "mkv", "webm", "3gp"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }

    private func extractAudio(from sourceURL: URL, to destinationURL: URL) async throws {
        let asset = AVURLAsset(url: sourceURL)

        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw ImportError.noAudioTrack
        }

        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw ImportError.exporterUnavailable
        }
        exporter.outputURL = destinationURL
        exporter.outputFileType = .m4a

        await withCheckedContinuation { continuation in
            exporter.exportAsynchronously {
                continuation.resume()
            }
        }

        switch exporter.status {
        case .completed:
            return
        case .failed, .cancelled:
            throw ImportError.exportFailed(exporter.error)
        default:
            throw ImportError.exportFailed(nil)
        }
    }

    private func makePlaceholderWaveform(for fileURL: URL) -> [Double] {
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 1_024
        return (0 ..< 48).map { index in
            let value = ((fileSize / max(index + 1, 1)) % 17) + 4
            return min(0.9, max(0.18, Double(value) / 22.0))
        }
    }
}
