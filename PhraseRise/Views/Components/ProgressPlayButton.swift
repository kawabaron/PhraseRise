import SwiftUI

struct ProgressPlayButton: View {
    let isPlaying: Bool
    let progress: Double
    var size: CGFloat = 40
    var baseFill: Color = AppColors.surface
    var activeFill: Color = AppColors.recording
    var iconColor: Color = AppColors.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isPlaying ? activeFill.opacity(0.22) : baseFill)

                if isPlaying {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        Rectangle()
                            .fill(activeFill)
                            .frame(width: max(0, width * CGFloat(min(max(progress, 0), 1))), height: height)
                    }
                    .clipShape(Circle())
                }

                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .frame(width: size, height: size)
            .overlay(Circle().stroke(AppColors.border, lineWidth: 1))
            .animation(.linear(duration: 0.1), value: progress)
        }
        .buttonStyle(.plain)
    }
}
