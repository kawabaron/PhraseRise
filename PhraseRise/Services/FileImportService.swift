import AVFoundation
import Foundation
import UIKit
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
        var videoDestinationURL: URL?
        var thumbnailDestinationURL: URL?

        if Self.isVideo(url: sourceURL) {
            destinationURL = AudioFileStorage.uniqueAudioFileURL(in: songsDirectory, fileExtension: "m4a")

            let videosDirectory = try AudioFileStorage.videosDirectory(fileManager: fileManager)
            let videoExtension = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
            let videoURL = AudioFileStorage.uniqueAudioFileURL(in: videosDirectory, fileExtension: videoExtension)
            try fileManager.copyItem(at: sourceURL, to: videoURL)
            videoDestinationURL = videoURL

            try await extractAudio(from: videoURL, to: destinationURL)

            let thumbnailsDirectory = try AudioFileStorage.thumbnailsDirectory(fileManager: fileManager)
            let thumbnailURL = AudioFileStorage.uniqueAudioFileURL(in: thumbnailsDirectory, fileExtension: "jpg")
            if (try? await generateThumbnail(from: videoURL, to: thumbnailURL)) != nil {
                thumbnailDestinationURL = thumbnailURL
            }
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
            videoFileURL: videoDestinationURL,
            thumbnailFileURL: thumbnailDestinationURL,
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

    private func generateThumbnail(from videoURL: URL, to destinationURL: URL) async throws {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 480)

        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)
        let targetSeconds = seconds.isFinite && seconds > 0 ? min(1.0, seconds / 2) : 0
        let time = CMTime(seconds: targetSeconds, preferredTimescale: 600)

        let cgImage: CGImage = try await withCheckedThrowingContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, error in
                if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "FileImportService", code: -1))
                }
            }
        }

        let uiImage = UIImage(cgImage: cgImage)
        guard let data = uiImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "FileImportService", code: -2)
        }
        try data.write(to: destinationURL)
    }

    private func makePlaceholderWaveform(for fileURL: URL) -> [Double] {
        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 1_024
        return (0 ..< 48).map { index in
            let value = ((fileSize / max(index + 1, 1)) % 17) + 4
            return min(0.9, max(0.18, Double(value) / 22.0))
        }
    }
}
