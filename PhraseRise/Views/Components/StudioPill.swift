import SwiftUI

struct StudioFilterPill: View {
    let title: String
    var value: String? = nil
    var tint: Color = AppColors.accent
    var isSelected = false

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(AppTypography.captionStrong)
                .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)

            if let value {
                Text(value)
                    .font(AppTypography.micro)
                    .foregroundStyle(isSelected ? Color.black : AppColors.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(isSelected ? tint : AppColors.surfaceInteractive)
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(isSelected ? tint.opacity(0.18) : AppColors.surfaceMuted.opacity(0.92))
        )
        .overlay(
            Capsule()
                .stroke(isSelected ? tint.opacity(0.55) : AppColors.border, lineWidth: 1)
        )
    }
}

struct StudioInlineMetricPill: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = AppColors.accent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(
                    Circle()
                        .fill(tint.opacity(0.16))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(AppTypography.eyebrow)
                    .tracking(1.2)
                    .foregroundStyle(AppColors.textMuted)
                Text(value)
                    .font(AppTypography.captionStrong)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(AppColors.surfaceMuted.opacity(0.92))
        )
        .overlay(
            Capsule()
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}
