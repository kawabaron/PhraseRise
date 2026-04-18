import SwiftUI

struct SourceAddMethodSheet: View {
    let onPickFiles: () -> Void
    let onPickMicRecording: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ADD SOURCE")
                    .font(AppTypography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AppColors.textMuted)

                Text("練習音源を追加")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Files またはマイク録音から Song を作成します。")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.xLarge)

            VStack(spacing: 0) {
                methodRow(
                    icon: "folder",
                    title: "Files から追加",
                    subtitle: "保存済みの音声ファイルを選ぶ",
                    tint: AppColors.accent,
                    action: onPickFiles
                )
                hairline
                methodRow(
                    icon: "mic.fill",
                    title: "練習音源を録音",
                    subtitle: "マイクから直接録音する",
                    tint: AppColors.recording,
                    action: onPickMicRecording
                )
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .studioScreen()
    }

    private func methodRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(tint.opacity(0.15)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var hairline: some View {
        Rectangle()
            .fill(AppColors.border)
            .frame(height: 0.5)
            .padding(.leading, AppSpacing.screenHorizontal + 50)
    }
}
