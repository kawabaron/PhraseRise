import AVFoundation
import Foundation

@MainActor
final class AudioPreviewService: NSObject {
    private let audioSessionCoordinator: AudioSessionCoordinator
    private var player: AVAudioPlayer?
    private var playingURL: URL?
    private var delegateProxy: PreviewDelegateProxy?

    var onFinish: (() -> Void)?

    init(audioSessionCoordinator: AudioSessionCoordinator) {
        self.audioSessionCoordinator = audioSessionCoordinator
    }

    var isPlaying: Bool {
        player?.isPlaying ?? false
    }

    var currentTime: Double {
        player?.currentTime ?? 0
    }

    var duration: Double {
        player?.duration ?? 0
    }

    func togglePreview(for url: URL) throws -> Bool {
        if playingURL == url, isPlaying {
            stopPreview()
            return false
        }

        try audioSessionCoordinator.configureForPreviewPlayback()
        let player = try AVAudioPlayer(contentsOf: url)
        let proxy = PreviewDelegateProxy { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.player = nil
                self.playingURL = nil
                self.delegateProxy = nil
                self.audioSessionCoordinator.deactivate()
                self.onFinish?()
            }
        }
        player.delegate = proxy
        player.prepareToPlay()
        player.play()
        self.player = player
        self.playingURL = url
        self.delegateProxy = proxy
        return true
    }

    func stopPreview() {
        player?.stop()
        player = nil
        playingURL = nil
        delegateProxy = nil
        audioSessionCoordinator.deactivate()
    }
}

private final class PreviewDelegateProxy: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        onFinish()
    }
}
