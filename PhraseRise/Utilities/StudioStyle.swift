import SwiftUI

struct StudioScreenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppColors.screenGradient.ignoresSafeArea())
    }
}

extension View {
    func studioScreen() -> some View {
        modifier(StudioScreenModifier())
    }
}
