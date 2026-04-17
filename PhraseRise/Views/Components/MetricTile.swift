import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        StudioCard(emphasisColor: tint) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColors.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Text(value)
                    .font(AppTypography.metric)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
