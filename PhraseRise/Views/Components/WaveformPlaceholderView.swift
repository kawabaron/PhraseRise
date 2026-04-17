import SwiftUI

struct WaveformPlaceholderView: View {
    let values: [Double]
    var selection: ClosedRange<Double>?
    var headPosition: Double?
    var showHead: Bool = true

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let height = max(geometry.size.height, 1)

            ZStack {
                RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                    .fill(AppColors.cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )

                if let selection {
                    selectionOverlay(selection: selection, width: width, height: height)
                }

                HStack(alignment: .center, spacing: 4) {
                    ForEach(Array(values.enumerated()), id: \.offset) { sample in
                        let ratio = Double(sample.offset) / Double(max(values.count - 1, 1))
                        Capsule()
                            .fill(barColor(for: ratio))
                            .frame(width: 4, height: max(8, height * sample.element))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.medium)

                if let selection {
                    handle(
                        x: selection.lowerBound * width,
                        width: width,
                        height: height
                    )
                    handle(
                        x: selection.upperBound * width,
                        width: width,
                        height: height
                    )
                }

                if showHead {
                    Rectangle()
                        .fill(Color.white.opacity(0.94))
                        .frame(width: 2)
                        .padding(.vertical, AppSpacing.small)
                        .shadow(color: Color.white.opacity(0.18), radius: 5, x: 0, y: 0)
                        .position(
                            x: min(max((headPosition ?? 0.5) * width, 1), width - 1),
                            y: height / 2
                        )
                }
            }
        }
    }

    private func selectionOverlay(selection: ClosedRange<Double>, width: CGFloat, height: CGFloat) -> some View {
        let start = selection.lowerBound * width
        let end = selection.upperBound * width

        return RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppColors.accent.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.accent.opacity(0.32), lineWidth: 1)
            )
            .frame(width: max(end - start, 24))
            .position(x: (start + end) / 2, y: height / 2)
    }

    private func handle(x: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        Capsule()
            .fill(AppColors.accent)
            .frame(width: 10, height: max(44, height - 32))
            .shadow(color: AppColors.accent.opacity(0.28), radius: 10, x: 0, y: 4)
            .position(x: min(max(x, 8), width - 8), y: height / 2)
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
