import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        StudioCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(value)
                    .font(AppTypography.metric)
                Capsule()
                    .fill(tint)
                    .frame(width: 42, height: 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
