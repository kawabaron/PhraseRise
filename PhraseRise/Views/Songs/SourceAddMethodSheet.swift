import SwiftUI

struct SourceAddMethodSheet: View {
    let onPickFiles: () -> Void
    let onPickMicRecording: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            StudioSectionHeader("練習音源を追加", subtitle: "Task 04 と Task 05 の入口")

            Button(action: onPickFiles) {
                Label("Files から追加", systemImage: "folder.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledStudioButtonStyle(tint: AppColors.accent))

            Button(action: onPickMicRecording) {
                Label("練習音源を録音", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledStudioButtonStyle(tint: AppColors.recording))
        }
        .padding(AppSpacing.large)
        .studioScreen()
    }
}
