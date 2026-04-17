import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("PhraseRise Premium", subtitle: "押し売りではなく、練習継続の価値を伝える")

                StudioCard {
                    VStack(alignment: .leading, spacing: 12) {
                        feature("Phrase 無制限")
                        feature("演奏録音 無制限")
                        feature("比較再生")
                        feature("全期間グラフ")
                        feature("次回提案フル機能")
                    }
                }

                Button("Premium を確認") {
                    dismiss()
                }
                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))

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
