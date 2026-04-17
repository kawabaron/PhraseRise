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
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("PhraseRise Premium", subtitle: "録音を貯めて比較しながら、難所フレーズを無制限に管理できます。")

                if let message {
                    StudioCard {
                        Text(message)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                StudioCard {
                    VStack(alignment: .leading, spacing: 12) {
                        feature("Phrase を無制限に保存")
                        feature("演奏録音を無制限に保存")
                        feature("2件の比較再生")
                        feature("全期間グラフ")
                        feature("次回提案のフル機能")
                    }
                }

                Button(viewModel.subscription.isPremium ? "Premium 利用中" : "Premium を有効化") {
                    viewModel.upgradeToPremium()
                    dismiss()
                }
                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))

                if viewModel.subscription.isPremium {
                    Button("無料版に戻す") {
                        viewModel.restoreFree()
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.surfaceRaised))
                }

                Button("閉じる") {
                    dismiss()
                }
                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accentMuted))

                Spacer()
            }
            .padding(AppSpacing.large)
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .studioScreen()
        }
    }

    private func feature(_ title: String) -> some View {
        Label(title, systemImage: "checkmark.circle.fill")
            .foregroundStyle(AppColors.textPrimary)
    }
}
