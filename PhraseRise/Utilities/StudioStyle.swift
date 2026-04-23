import SwiftUI

private struct StudioBackdrop: View {
    var body: some View {
        ZStack {
            AppColors.screenGradient
            AppColors.backdropGradient

            RadialGradient(
                colors: [
                    AppColors.accent.opacity(0.20),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 300
            )
            .offset(x: -80, y: -120)

            RadialGradient(
                colors: [
                    AppColors.progress.opacity(0.12),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: 260
            )
            .offset(x: 110, y: 120)
        }
    }
}

struct StudioScreenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(StudioBackdrop().ignoresSafeArea())
    }
}

extension View {
    func studioScreen() -> some View {
        modifier(StudioScreenModifier())
    }
}
