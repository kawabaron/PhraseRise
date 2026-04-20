import Foundation

enum PhraseLoopBoundaryAction {
    case none
    case restart(Double)
    case stop(Double)
}

struct PhraseLoopService {
    private let minimumDurationSec = 0.15

    func initialRange(for phrase: Phrase, song: Song) -> ClosedRange<Double> {
        clampRange(
            start: phrase.startTimeSec,
            end: phrase.endTimeSec,
            songDurationSec: song.durationSec
        )
    }

    func clampRange(start: Double, end: Double, songDurationSec: Double) -> ClosedRange<Double> {
        let clampedStart = min(max(0, start), max(songDurationSec - minimumDurationSec, 0))
        let clampedEnd = min(max(clampedStart + minimumDurationSec, end), max(songDurationSec, minimumDurationSec))
        return clampedStart ... clampedEnd
    }

    func selectionRatio(for range: ClosedRange<Double>, songDurationSec: Double) -> ClosedRange<Double> {
        guard songDurationSec > 0 else { return 0.1 ... 0.3 }
        let start = min(max(range.lowerBound / songDurationSec, 0), 1)
        let end = min(max(range.upperBound / songDurationSec, 0), 1)
        return start ... max(end, start + 0.01)
    }

    func headRatio(currentTimeSec: Double, songDurationSec: Double) -> Double {
        guard songDurationSec > 0 else { return 0 }
        return min(max(currentTimeSec / songDurationSec, 0), 1)
    }

    func boundaryAction(
        currentTimeSec: Double,
        range: ClosedRange<Double>,
        isLoopEnabled: Bool,
        songDurationSec: Double
    ) -> PhraseLoopBoundaryAction {
        if currentTimeSec >= range.upperBound {
            return isLoopEnabled ? .restart(range.lowerBound) : .stop(range.upperBound)
        }

        if currentTimeSec >= songDurationSec {
            return .stop(songDurationSec)
        }

        return .none
    }

    func clampedSeekTarget(
        currentTimeSec: Double,
        deltaSec: Double,
        songDurationSec: Double
    ) -> Double {
        min(max(0, currentTimeSec + deltaSec), songDurationSec)
    }
}
