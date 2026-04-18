import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let message: String?
    @State private var viewModel: PaywallViewModel

    init(dependencies: AppDependencies, message: String? = nil) {
        self.message = message
        _viewModel = State(initialValue: PaywallViewModel(dependencies: dependencies))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                heroSection

                if let message {
                    Text(message)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.top, AppSpacing.medium)
                }

                featuresSection
                    .padding(.top, AppSpacing.medium)

                Spacer(minLength: AppSpacing.medium)

                actionStack
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.medium)
            }
            .frame(maxHeight: .infinity)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .studioScreen()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PHRASERISE")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)

            Text("Premium")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.medium)
        .background(
            RadialGradient(
                colors: [
                    AppColors.accent.opacity(0.22),
                    Color.clear
                ],
                center: UnitPoint(x: 0.1, y: 0.0),
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("INCLUDED")
                .font(AppTypography.eyebrow)
                .tracking(2)
                .foregroundStyle(AppColors.textMuted)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.small)

            featureRow("練習区間を無制限に保存")
            hairline
            featureRow("演奏録音を無制限に保存")
            hairline
            featureRow("2件の比較再生")
            hairline
            featureRow("全期間グラフ")
            hairline
            featureRow("次回提案のフル機能")
        }
    }

    private func featureRow(_ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.accent)
                .frame(width: 20)
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, 10)
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(height: 0.5)
            .padding(.leading, AppSpacing.screenHorizontal + 32)
    }

    private var actionStack: some View {
        VStack(spacing: AppSpacing.small) {
            Button {
                viewModel.upgradeToPremium()
                dismiss()
            } label: {
                Text(viewModel.subscription.isPremium ? "Premium 利用中" : "Premium を有効化")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppColors.accent)
                    )
            }
            .buttonStyle(.plain)

            if viewModel.subscription.isPremium {
                Button("無料版に戻す") {
                    viewModel.restoreFree()
                }
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.vertical, 12)
            }
        }
    }
}
