import SwiftUI

struct MetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        StudioCard(emphasisColor: tint) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title.uppercased())
                    .font(AppTypography.eyebrow)
                    .foregroundStyle(AppColors.textSecondary)

                Text(value)
                    .font(AppTypography.metric)

                Capsule()
                    .fill(tint)
                    .frame(width: 44, height: 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
