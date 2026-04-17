import SwiftUI

enum AppColors {
    static let background = Color(red: 0.055, green: 0.066, blue: 0.086)
    static let backgroundSecondary = Color(red: 0.070, green: 0.082, blue: 0.106)
    static let surface = Color(red: 0.118, green: 0.137, blue: 0.169)
    static let surfaceRaised = Color(red: 0.145, green: 0.169, blue: 0.204)
    static let surfaceGlass = Color(red: 0.180, green: 0.210, blue: 0.260)
    static let border = Color.white.opacity(0.08)
    static let shadow = Color.black.opacity(0.34)

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
            background,
            background
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [
            surfaceRaised,
            surface
        ],
        startPoint: .top,
        endPoint: .bottom
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
