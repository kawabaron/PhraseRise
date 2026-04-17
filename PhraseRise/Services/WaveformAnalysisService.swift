import AVFoundation
import Foundation

struct WaveformAnalysisService {
    func analyzeWaveform(url: URL, sampleCount: Int = 64) throws -> [Double] {
        let resolvedCount = max(16, sampleCount)
        let audioFile = try AVAudioFile(forReading: url)
        let totalFrames = Int(audioFile.length)

        guard totalFrames > 0 else {
            return Array(repeating: 0.2, count: resolvedCount)
        }

        let format = audioFile.processingFormat
        let framesPerBucket = max(totalFrames / resolvedCount, 1)
        let chunkSize = min(max(framesPerBucket, 2_048), 8_192)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(chunkSize)
        ) else {
            return Array(repeating: 0.2, count: resolvedCount)
        }

        var peaks = Array(repeating: Float.zero, count: resolvedCount)
        var frameOffset = 0

        audioFile.framePosition = 0
        while frameOffset < totalFrames {
            let remainingFrames = totalFrames - frameOffset
            let requestedFrames = min(chunkSize, remainingFrames)
            try audioFile.read(into: buffer, frameCount: AVAudioFrameCount(requestedFrames))

            let readFrames = Int(buffer.frameLength)
            guard readFrames > 0 else { break }

            guard let channelData = buffer.floatChannelData else {
                return Array(repeating: 0.2, count: resolvedCount)
            }

            let channelCount = Int(format.channelCount)
            for frame in 0 ..< readFrames {
                var framePeak: Float = 0
                for channel in 0 ..< channelCount {
                    framePeak = max(framePeak, abs(channelData[channel][frame]))
                }
                let bucket = min((frameOffset + frame) / framesPerBucket, resolvedCount - 1)
                peaks[bucket] = max(peaks[bucket], framePeak)
            }

            frameOffset += readFrames
        }

        let maxPeak = peaks.max() ?? 0
        guard maxPeak > 0 else {
            return Array(repeating: 0.2, count: resolvedCount)
        }

        return peaks.map { peak in
            let normalized = Double(peak / maxPeak)
            return min(0.96, max(0.12, normalized))
        }
    }

    func durationSec(for url: URL) -> Double {
        let asset = AVURLAsset(url: url)
        let seconds = CMTimeGetSeconds(asset.duration)
        return seconds.isFinite ? max(0, seconds) : 0
    }
}
