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
                    .fill(
                        LinearGradient(
                            colors: [
                                emphasisColor.opacity(0.9),
                                emphasisColor.opacity(0.35)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
            }

            content
                .padding(AppSpacing.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(cardBackground)
        .clipShape(cardShape)
        .overlay(cardShape.stroke(AppColors.borderStrong, lineWidth: 1))
        .shadow(color: AppColors.shadow, radius: 14, x: 0, y: 6)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
    }

    private var cardBackground: some View {
        cardShape
            .fill(AppColors.cardGradient)
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppCorners.card, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                (emphasisColor ?? AppColors.surfaceGlass).opacity(0.18),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                cardShape
                    .stroke(Color.white.opacity(0.03), lineWidth: 0.5)
                    .padding(1)
            }
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
                .tracking(0.2)
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
