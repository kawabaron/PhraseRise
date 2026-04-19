import Foundation

@MainActor
final class PlaybackProgressTicker {
    private nonisolated(unsafe) var timer: Timer?
    private let interval: TimeInterval
    private let onTick: @MainActor () -> Void

    init(interval: TimeInterval = 0.05, onTick: @escaping @MainActor () -> Void) {
        self.interval = interval
        self.onTick = onTick
    }

    deinit {
        timer?.invalidate()
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [onTick] _ in
            Task { @MainActor in
                onTick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
