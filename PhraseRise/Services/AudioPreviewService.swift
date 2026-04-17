import AVFoundation
import Foundation

@MainActor
final class AudioPreviewService: NSObject {
    private let audioSessionCoordinator: AudioSessionCoordinator
    private var player: AVAudioPlayer?
    private var playingURL: URL?

    init(audioSessionCoordinator: AudioSessionCoordinator) {
        self.audioSessionCoordinator = audioSessionCoordinator
    }

    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    func togglePreview(for url: URL) throws -> Bool {
        if playingURL == url, isPlaying {
            stopPreview()
            return false
        }

        try audioSessionCoordinator.configureForPreviewPlayback()
        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        player.play()
        self.player = player
        self.playingURL = url
        return true
    }

    func stopPreview() {
        player?.stop()
        player = nil
        playingURL = nil
        audioSessionCoordinator.deactivate()
    }
}
