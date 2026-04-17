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
                    .fill(tint.opacity(configuration.isPressed ? 0.84 : 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCorners.button, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: tint.opacity(0.22), radius: 14, x: 0, y: 8)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct CircularRecordButton: View {
    let isRecording: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.recording.opacity(isRecording ? 0.24 : 0.12))
                .frame(width: 88, height: 88)
                .scaleEffect(isRecording ? 1.04 : 1.0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isRecording)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.recording.opacity(0.92),
                            AppColors.recording
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 66, height: 66)
                .overlay {
                    Image(systemName: isRecording ? "stop.fill" : "record.circle")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: AppColors.recording.opacity(0.28), radius: 14, x: 0, y: 8)
        }
    }
}
