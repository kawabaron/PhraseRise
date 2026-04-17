import SwiftUI

struct StudioCard<Content: View>: View {
    private let emphasisColor: Color?
    private let content: Content

    init(
        emphasisColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.emphasisColor = emphasisColor
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            if let emphasisColor {
                Rectangle()
                    .fill(emphasisColor)
                    .frame(width: 3)
            }

            content
                .padding(AppSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .shadow(color: AppColors.shadow, radius: 14, x: 0, y: 6)
    }

    private var cardBackground: some View {
        AppColors.cardGradient
    }
}

struct StudioSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
