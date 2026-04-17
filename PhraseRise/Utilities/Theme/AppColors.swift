import SwiftUI

enum AppColors {
    static let background = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let backgroundSecondary = Color(red: 0.11, green: 0.13, blue: 0.16)
    static let surface = Color(red: 0.12, green: 0.15, blue: 0.19)
    static let surfaceRaised = Color(red: 0.15, green: 0.18, blue: 0.22)
    static let border = Color.white.opacity(0.10)
    static let accent = Color(red: 0.17, green: 0.73, blue: 0.79)
    static let accentMuted = Color(red: 0.11, green: 0.38, blue: 0.41)
    static let recording = Color(red: 0.88, green: 0.22, blue: 0.24)
    static let success = Color(red: 0.33, green: 0.76, blue: 0.47)
    static let warning = Color(red: 0.92, green: 0.58, blue: 0.20)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textMuted = Color.white.opacity(0.50)

    static let screenGradient = LinearGradient(
        colors: [
            background,
            backgroundSecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
