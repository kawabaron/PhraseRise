import SwiftUI

struct MicSourceRecordView: View {
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isRecording = false
    @State private var elapsedSec = 0
    @State private var inputLevel = 0.54

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                StudioSectionHeader("練習音源を録音", subtitle: "ここでは Song 作成用の練習音源のみ扱います")

                StudioCard {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Label(isRecording ? "録音中" : "待機中", systemImage: isRecording ? "record.circle.fill" : "pause.circle")
                                .foregroundStyle(isRecording ? AppColors.recording : AppColors.textSecondary)
                            Spacer()
                            Text(Formatting.duration(Double(elapsedSec)))
                                .font(AppTypography.metric)
                        }

                        ProgressView(value: inputLevel)
                            .tint(AppColors.recording)

                        Text("権限未許可時は Task 16 で設定アプリ導線を接続します。")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                HStack(spacing: AppSpacing.medium) {
                    Button {
                        isRecording.toggle()
                        if isRecording { elapsedSec += 18 }
                    } label: {
                        Label(isRecording ? "一時停止" : "録音開始", systemImage: isRecording ? "pause.fill" : "record.circle")
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.recording))

                    Button("停止して保存へ") {
                        onConfirm()
                    }
                    .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))
                }

                Button("破棄") {
                    dismiss()
                }
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)

                Spacer()
            }
            .padding(AppSpacing.large)
            .navigationTitle("練習音源を録音")
            .navigationBarTitleDisplayMode(.inline)
            .studioScreen()
        }
    }
}
