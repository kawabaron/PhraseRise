import SwiftUI

struct SourceSaveConfirmView: View {
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = "新しい練習音源"

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("練習音源を保存", subtitle: "Task 04 / 05 で実ファイル保存へ接続")

                WaveformPlaceholderView(values: Array(repeating: 0.4, count: 40).enumerated().map { index, _ in
                    0.24 + (Double((index * 7) % 12) / 22.0)
                })
                .frame(height: 180)

                StudioCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("音源名")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        TextField("タイトル", text: $title)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppColors.backgroundSecondary)
                            )
                    }
                }

                Button("練習音源を保存") {
                    onSave()
                    dismiss()
                }
                .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))

                Spacer()
            }
            .padding(AppSpacing.large)
            .navigationTitle("保存確認")
            .navigationBarTitleDisplayMode(.inline)
            .studioScreen()
        }
    }
}
