import SwiftUI

enum AppColors {
    static let background = Color(red: 0.028, green: 0.041, blue: 0.064)
    static let backgroundSecondary = Color(red: 0.042, green: 0.058, blue: 0.086)
    static let backgroundTertiary = Color(red: 0.060, green: 0.079, blue: 0.112)

    static let surface = Color(red: 0.090, green: 0.112, blue: 0.150)
    static let surfaceRaised = Color(red: 0.116, green: 0.144, blue: 0.188)
    static let surfaceGlass = Color(red: 0.156, green: 0.186, blue: 0.236)
    static let surfaceMuted = Color(red: 0.086, green: 0.102, blue: 0.132)
    static let surfaceInteractive = Color(red: 0.128, green: 0.156, blue: 0.198)

    static let border = Color.white.opacity(0.08)
    static let borderStrong = Color.white.opacity(0.16)
    static let shadow = Color.black.opacity(0.34)

    static let accent = Color(red: 0.14, green: 0.79, blue: 0.82)
    static let accentStrong = Color(red: 0.26, green: 0.90, blue: 0.92)
    static let accentSoft = Color(red: 0.11, green: 0.30, blue: 0.33)
    static let progress = Color(red: 0.96, green: 0.70, blue: 0.28)
    static let progressSoft = Color(red: 0.33, green: 0.24, blue: 0.09)
    static let recording = Color(red: 0.92, green: 0.36, blue: 0.36)
    static let recordingSoft = Color(red: 0.36, green: 0.12, blue: 0.13)
    static let success = Color(red: 0.39, green: 0.82, blue: 0.53)
    static let warning = Color(red: 0.92, green: 0.62, blue: 0.28)

    static let textPrimary = Color.white.opacity(0.98)
    static let textSecondary = Color.white.opacity(0.78)
    static let textMuted = Color.white.opacity(0.56)

    static let screenGradient = LinearGradient(
        colors: [
            background,
            backgroundSecondary,
            background
        ],
        startPoint: .topLeading,
        endPoint: .bottom
    )

    static let backdropGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.02),
            Color.clear,
            Color.black.opacity(0.12)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [
            surfaceRaised,
            surface,
            surfaceMuted
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardInteractiveGradient = LinearGradient(
        colors: [
            surfaceInteractive,
            surfaceRaised,
            surface
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.21, blue: 0.24),
            Color(red: 0.07, green: 0.11, blue: 0.15),
            Color(red: 0.04, green: 0.07, blue: 0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
