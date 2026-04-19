import AVFoundation
import Foundation

@MainActor
final class ClickTrackService {
    private let audioSessionCoordinator: AudioSessionCoordinator
    private var cachedClickURL: URL?
    private var scheduledTasks: [Task<Void, Never>] = []

    init(audioSessionCoordinator: AudioSessionCoordinator) {
        self.audioSessionCoordinator = audioSessionCoordinator
    }

    func playCountIn(bpm: Int, beatCount: Int = 4) async {
        cancelPending()
        guard beatCount > 0 else { return }

        let beatInterval = 60.0 / Double(max(bpm, 30))

        do {
            try audioSessionCoordinator.configureForPreviewPlayback()
        } catch {
            return
        }

        guard let url = try? ensureClickFile() else { return }

        for beat in 0 ..< beatCount {
            let delayNs = UInt64(Double(beat) * beatInterval * 1_000_000_000)
            let isAccent = beat == 0
            let task = Task { @MainActor [weak self] in
                if delayNs > 0 {
                    try? await Task.sleep(nanoseconds: delayNs)
                }
                guard !Task.isCancelled else { return }
                self?.playOnce(url: url, accent: isAccent)
            }
            scheduledTasks.append(task)
        }

        let totalSleepNs = UInt64(Double(beatCount) * beatInterval * 1_000_000_000)
        try? await Task.sleep(nanoseconds: totalSleepNs)
    }

    func cancelPending() {
        for task in scheduledTasks {
            task.cancel()
        }
        scheduledTasks.removeAll()
    }

    private func playOnce(url: URL, accent: Bool) {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = accent ? 1.0 : 0.7
        player.prepareToPlay()
        player.play()

        let lifetimeNs = UInt64(0.25 * 1_000_000_000)
        Task { [player] in
            try? await Task.sleep(nanoseconds: lifetimeNs)
            _ = player
        }
    }

    private func ensureClickFile() throws -> URL {
        if let cachedClickURL, FileManager.default.fileExists(atPath: cachedClickURL.path) {
            return cachedClickURL
        }
        let url = try generateClickFile()
        cachedClickURL = url
        return url
    }

    private func generateClickFile() throws -> URL {
        let sampleRate: Double = 44_100
        let duration: Double = 0.05
        let frequency: Double = 2_000
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else {
            throw NSError(domain: "PhraseRise.Click", code: 1, userInfo: [NSLocalizedDescriptionKey: "クリック音を生成できませんでした。"])
        }

        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else {
            throw NSError(domain: "PhraseRise.Click", code: 2, userInfo: [NSLocalizedDescriptionKey: "クリック音のバッファを確保できませんでした。"])
        }

        for frame in 0 ..< Int(frameCount) {
            let t = Double(frame) / sampleRate
            let envelope = Float(exp(-t * 60))
            let sample = Float(sin(2 * .pi * frequency * t)) * envelope * 0.85
            channelData[frame] = sample
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("phraserise_click.caf")
        try? FileManager.default.removeItem(at: url)
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        return url
    }
}
