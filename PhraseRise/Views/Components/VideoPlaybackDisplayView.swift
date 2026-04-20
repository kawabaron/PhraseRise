import AVFoundation
import SwiftUI
import UIKit

struct VideoPlaybackDisplayView: View {
    let videoURL: URL
    let durationSec: Double
    var selection: ClosedRange<Double>?
    var headPosition: Double?
    var onSelectionChange: ((ClosedRange<Double>) -> Void)?

    private let horizontalInset: CGFloat = 12
    private let handleHitWidth: CGFloat = 44
    private let coordinateSpaceName = "videoTimelineCanvas"

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let height = max(geometry.size.height, 1)
            let usable = max(width - horizontalInset * 2, 1)

            ZStack {
                RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )

                VideoPreviewLayerView(
                    videoURL: videoURL,
                    durationSec: durationSec,
                    headPosition: headPosition
                )
                .clipShape(RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous))

                if let selection {
                    selectionOverlay(selection: selection, usable: usable, height: height)
                }

                if let selection, let onSelectionChange {
                    handle(
                        x: horizontalInset + CGFloat(selection.lowerBound) * usable,
                        height: height,
                        onDragTo: { locationX in
                            let newStart = clampRatio((locationX - horizontalInset) / usable)
                            let upper = selection.upperBound
                            let start = min(newStart, upper - 0.01)
                            onSelectionChange(start ... upper)
                        }
                    )
                    handle(
                        x: horizontalInset + CGFloat(selection.upperBound) * usable,
                        height: height,
                        onDragTo: { locationX in
                            let newEnd = clampRatio((locationX - horizontalInset) / usable)
                            let lower = selection.lowerBound
                            let end = max(newEnd, lower + 0.01)
                            onSelectionChange(lower ... end)
                        }
                    )
                } else if let selection {
                    staticHandle(x: horizontalInset + CGFloat(selection.lowerBound) * usable, height: height)
                    staticHandle(x: horizontalInset + CGFloat(selection.upperBound) * usable, height: height)
                }

                if let headPosition {
                    Rectangle()
                        .fill(Color.white.opacity(0.94))
                        .frame(width: 2)
                        .padding(.vertical, AppSpacing.small)
                        .shadow(color: Color.white.opacity(0.18), radius: 5, x: 0, y: 0)
                        .position(
                            x: horizontalInset + CGFloat(headPosition) * usable,
                            y: height / 2
                        )
                }
            }
            .coordinateSpace(name: coordinateSpaceName)
        }
    }

    private func selectionOverlay(selection: ClosedRange<Double>, usable: CGFloat, height: CGFloat) -> some View {
        let start = horizontalInset + CGFloat(selection.lowerBound) * usable
        let end = horizontalInset + CGFloat(selection.upperBound) * usable

        return RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppColors.accent.opacity(0.18))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.accent.opacity(0.45), lineWidth: 1)
            )
            .frame(width: max(end - start, 24))
            .position(x: (start + end) / 2, y: height / 2)
    }

    private func staticHandle(x: CGFloat, height: CGFloat) -> some View {
        Capsule()
            .fill(AppColors.accent)
            .frame(width: 10, height: max(44, height - 32))
            .shadow(color: AppColors.accent.opacity(0.28), radius: 10, x: 0, y: 4)
            .position(x: x, y: height / 2)
    }

    private func handle(
        x: CGFloat,
        height: CGFloat,
        onDragTo: @escaping (CGFloat) -> Void
    ) -> some View {
        let handleHeight = max(44, height - 32)
        return ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: handleHitWidth, height: handleHeight)
            Capsule()
                .fill(AppColors.accent)
                .frame(width: 10, height: handleHeight)
                .shadow(color: AppColors.accent.opacity(0.28), radius: 10, x: 0, y: 4)
        }
        .contentShape(Rectangle())
        .position(x: x, y: height / 2)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName))
                .onChanged { value in
                    onDragTo(value.location.x)
                }
        )
    }

    private func clampRatio(_ value: CGFloat) -> Double {
        Double(min(max(value, 0), 1))
    }
}

private struct VideoPreviewLayerView: UIViewRepresentable {
    let videoURL: URL
    let durationSec: Double
    let headPosition: Double?

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.configure(with: videoURL)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.configure(with: videoURL)
        uiView.updatePlayback(headRatio: headPosition, durationSec: durationSec)
    }
}

private final class PlayerContainerView: UIView {
    private var player: AVPlayer?
    private var currentURL: URL?
    private var lastSeekSeconds: Double = -1
    private var isPlaying = false

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer {
        // swiftlint:disable:next force_cast
        layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspect
    }

    func configure(with url: URL) {
        if currentURL == url, player != nil { return }
        let newPlayer = AVPlayer(url: url)
        newPlayer.isMuted = true
        newPlayer.actionAtItemEnd = .pause
        newPlayer.automaticallyWaitsToMinimizeStalling = false
        playerLayer.player = newPlayer
        player = newPlayer
        currentURL = url
        lastSeekSeconds = -1
        isPlaying = false
    }

    func updatePlayback(headRatio: Double?, durationSec: Double) {
        guard let player else { return }

        guard let headRatio, durationSec > 0 else {
            if isPlaying {
                player.pause()
                isPlaying = false
            }
            return
        }

        let targetSeconds = max(0, min(durationSec, headRatio * durationSec))
        let currentSeconds = CMTimeGetSeconds(player.currentTime())
        let drift = abs(currentSeconds - targetSeconds)

        if drift > 0.25 || abs(lastSeekSeconds - targetSeconds) > 0.25 {
            let time = CMTime(seconds: targetSeconds, preferredTimescale: 600)
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
            lastSeekSeconds = targetSeconds
        }

        if !isPlaying {
            player.play()
            isPlaying = true
        }
    }
}
