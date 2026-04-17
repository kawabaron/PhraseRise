import SwiftUI

struct FilledStudioButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppCorners.button, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.85 : 1))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct CircularRecordButton: View {
    let isRecording: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.recording.opacity(isRecording ? 0.25 : 0.15))
                .frame(width: 84, height: 84)
            Circle()
                .fill(AppColors.recording)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: isRecording ? "stop.fill" : "record.circle")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
    }
}
