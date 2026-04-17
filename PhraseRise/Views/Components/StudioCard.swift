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
        content
            .padding(AppSpacing.medium)
            .background(cardBackground)
            .overlay(alignment: .topLeading) {
                if let emphasisColor {
                    Capsule()
                        .fill(emphasisColor.opacity(0.92))
                        .frame(width: 52, height: 6)
                        .padding(.top, 14)
                        .padding(.leading, AppSpacing.medium)
                }
            }
            .shadow(color: AppColors.shadow, radius: 18, x: 0, y: 10)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
            .fill(AppColors.cardGradient)
            .overlay(
                RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    .blur(radius: 1)
            )
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
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
