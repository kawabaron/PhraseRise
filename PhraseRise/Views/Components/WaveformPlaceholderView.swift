import SwiftUI

struct WaveformPlaceholderView: View {
    let values: [Double]
    var selection: ClosedRange<Double>?
    var headPosition: Double?
    var showHead: Bool = true
    var onSelectionChange: ((ClosedRange<Double>) -> Void)?

    private let horizontalInset: CGFloat = 12
    private let barWidth: CGFloat = 4
    private let handleHitWidth: CGFloat = 44
    private let coordinateSpaceName = "waveformCanvas"

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let height = max(geometry.size.height, 1)
            let usable = max(width - horizontalInset * 2, 1)

            ZStack {
                RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                    .fill(AppColors.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )

                if let selection {
                    selectionOverlay(selection: selection, usable: usable, height: height)
                }

                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    let ratio = Double(index) / Double(max(values.count - 1, 1))
                    Capsule()
                        .fill(barColor(for: ratio))
                        .frame(width: barWidth, height: max(8, (height - AppSpacing.medium * 2) * value))
                        .position(x: horizontalInset + CGFloat(ratio) * usable, y: height / 2)
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

                if showHead {
                    let head = CGFloat(headPosition ?? 0.5)
                    Rectangle()
                        .fill(Color.white.opacity(0.94))
                        .frame(width: 2)
                        .padding(.vertical, AppSpacing.small)
                        .shadow(color: Color.white.opacity(0.18), radius: 5, x: 0, y: 0)
                        .position(
                            x: horizontalInset + head * usable,
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
            .fill(AppColors.accent.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.accent.opacity(0.32), lineWidth: 1)
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

    private func barColor(for ratio: Double) -> Color {
        guard let selection else {
            return AppColors.accent.opacity(0.86)
        }

        if selection.contains(ratio) {
            return AppColors.accent.opacity(0.92)
        }

        return Color.white.opacity(0.24)
    }
}
