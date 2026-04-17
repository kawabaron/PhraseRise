import SwiftUI

enum AppColors {
    static let background = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let backgroundSecondary = Color(red: 0.09, green: 0.11, blue: 0.14)
    static let surface = Color(red: 0.11, green: 0.13, blue: 0.17)
    static let surfaceRaised = Color(red: 0.14, green: 0.17, blue: 0.21)
    static let surfaceGlass = Color(red: 0.18, green: 0.21, blue: 0.26)
    static let border = Color.white.opacity(0.10)
    static let shadow = Color.black.opacity(0.28)

    static let accent = Color(red: 0.17, green: 0.73, blue: 0.79)
    static let accentSoft = Color(red: 0.12, green: 0.31, blue: 0.34)
    static let recording = Color(red: 0.88, green: 0.22, blue: 0.24)
    static let success = Color(red: 0.33, green: 0.76, blue: 0.47)
    static let warning = Color(red: 0.92, green: 0.58, blue: 0.20)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.74)
    static let textMuted = Color.white.opacity(0.52)

    static let screenGradient = LinearGradient(
        colors: [
            Color(red: 0.06, green: 0.08, blue: 0.10),
            background,
            backgroundSecondary
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            surfaceRaised.opacity(0.98),
            surface
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.11, green: 0.20, blue: 0.22),
            Color(red: 0.07, green: 0.10, blue: 0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
