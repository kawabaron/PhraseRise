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
                    .fill(AppColors.surfaceRaised)

                if let selection {
                    let start = selection.lowerBound * width
                    let end = selection.upperBound * width
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColors.accent.opacity(0.14))
                        .frame(width: max(end - start, 24))
                        .position(x: (start + end) / 2, y: height / 2)
                }

                HStack(alignment: .center, spacing: 4) {
                    ForEach(Array(values.enumerated()), id: \.offset) { sample in
                        Capsule()
                            .fill(AppColors.accent.opacity(0.8))
                            .frame(width: 4, height: max(8, height * sample.element))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.medium)

                if showHead {
                    Rectangle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 2)
                        .padding(.vertical, AppSpacing.small)
                        .position(
                            x: min(max((headPosition ?? 0.5) * width, 1), width - 1),
                            y: height / 2
                        )
                }
            }
        }
    }
}
